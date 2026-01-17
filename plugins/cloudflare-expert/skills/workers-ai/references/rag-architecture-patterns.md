# RAG Architecture Patterns

Advanced patterns for building production-quality RAG (Retrieval Augmented Generation) systems on Cloudflare Workers.

## Document Store Abstraction

Create an abstraction layer to manage interactions with R2, D1, and Vectorize:

```typescript
export class DocumentStore {
  constructor(
    private env: Env,
    private logger: Logger
  ) {}

  // Article Operations (R2)
  async storeArticle(article: Article): Promise<void> {
    await this.env.ARTICLES_BUCKET.put(
      `articles/${article.id}.json`,
      JSON.stringify(article),
      {
        httpMetadata: { contentType: 'application/json' },
        customMetadata: { title: article.title }
      }
    );
  }

  async getArticle(articleId: string): Promise<Article | null> {
    const object = await this.env.ARTICLES_BUCKET.get(`articles/${articleId}.json`);
    if (!object) return null;
    return object.json() as Promise<Article>;
  }

  // Document Metadata (D1)
  async createDocument(doc: DocumentMetadata): Promise<void> {
    await this.env.DATABASE
      .prepare('INSERT INTO documents (id, article_id, title, metadata) VALUES (?, ?, ?, ?)')
      .bind(doc.id, doc.articleId, doc.title, JSON.stringify(doc.metadata))
      .run();
  }

  // Chunk Operations (D1)
  async createChunks(chunks: TextChunk[]): Promise<void> {
    for (const chunk of chunks) {
      await this.env.DATABASE
        .prepare('INSERT INTO chunks (id, document_id, text, chunk_index, metadata) VALUES (?, ?, ?, ?, ?)')
        .bind(chunk.id, chunk.documentId, chunk.text, chunk.index, JSON.stringify(chunk.metadata))
        .run();
    }
  }

  async getChunksWithMetadata(chunkIds: string[]): Promise<ChunkWithMetadata[]> {
    const placeholders = chunkIds.map(() => '?').join(',');
    const { results } = await this.env.DATABASE
      .prepare(`
        SELECT c.*, d.title, d.article_id, d.metadata as doc_metadata
        FROM chunks c
        JOIN documents d ON c.document_id = d.id
        WHERE c.id IN (${placeholders})
      `)
      .bind(...chunkIds)
      .all();
    return results.map(this.mapChunkRow);
  }

  // Vector Operations (Vectorize)
  async insertVectors(vectors: VectorData[]): Promise<void> {
    await this.env.VECTOR_INDEX.upsert(vectors);
  }

  async queryVectors(embedding: number[], topK: number = 3): Promise<VectorMatch[]> {
    const results = await this.env.VECTOR_INDEX.query(embedding, {
      topK,
      returnMetadata: true
    });
    return results.matches;
  }
}

// Factory function
export function createDocumentStore(env: Env, logger: Logger): DocumentStore {
  return new DocumentStore(env, logger);
}
```

### Benefits

- Single interface for all storage operations
- Centralized error handling and logging
- Easy to test with mocks
- Clear separation of concerns
- Transaction-like operations across bindings

## Wikipedia-Aware Chunking

For content with structure (headers, lists, tables), use structure-aware chunking:

```typescript
import { RecursiveCharacterTextSplitter } from '@langchain/textsplitters';

interface ChunkingOptions {
  chunkSize?: number;
  chunkOverlap?: number;
}

export function createWikipediaSplitter(options: ChunkingOptions = {}): RecursiveCharacterTextSplitter {
  return new RecursiveCharacterTextSplitter({
    chunkSize: options.chunkSize || 500,
    chunkOverlap: options.chunkOverlap || 100,
    separators: [
      '\n\n\n',  // Section breaks (major divisions)
      '\n\n',    // Paragraph breaks
      '\n',      // Line breaks
      '. ',      // Sentence boundaries
      ' ',       // Word boundaries (last resort)
    ],
  });
}

export async function chunkWikipediaArticle(
  content: string,
  title: string,
  options: ChunkingOptions = {}
): Promise<TextChunk[]> {
  const splitter = createWikipediaSplitter(options);
  const documents = await splitter.createDocuments([content]);

  return documents.map((doc, index) => ({
    text: doc.pageContent,
    index,
    metadata: {
      title,
      chunkSize: doc.pageContent.length,
      hasTable: doc.pageContent.includes('|'),      // Wiki table syntax
      hasList: /^[*#]/m.test(doc.pageContent),       // Wiki list syntax
      hasHeader: /^={2,}/m.test(doc.pageContent),   // Wiki header syntax
    },
  }));
}

// Estimate chunk count for progress reporting
export function estimateChunkCount(
  contentLength: number,
  chunkSize: number = 500,
  chunkOverlap: number = 100
): number {
  if (contentLength <= chunkSize) return 1;
  const effectiveChunkSize = chunkSize - chunkOverlap;
  return Math.ceil((contentLength - chunkSize) / effectiveChunkSize) + 1;
}
```

### Chunking Strategies by Content Type

| Content Type | Chunk Size | Overlap | Separators |
|--------------|------------|---------|------------|
| General text | 400-500 | 50-100 | Paragraphs → sentences |
| Technical docs | 300-400 | 50 | Headers → paragraphs |
| Code | 200-300 | 0 | Functions → lines |
| Legal/contracts | 500-600 | 100 | Sections → paragraphs |
| Chat logs | 200-300 | 0 | Messages |

## Strict RAG System Prompts

Prevent hallucination with carefully crafted system prompts:

```typescript
const STRICT_RAG_SYSTEM_PROMPT = `You are a helpful assistant that answers questions based ONLY on the provided context.

RULES:
1. ONLY use information from the provided context to answer
2. If the answer is not in the context, say "I don't have enough information to answer that question based on the available documents."
3. NEVER make up information or use knowledge outside the context
4. Quote relevant passages when helpful
5. Cite the source title when referencing specific information
6. If the question is ambiguous, ask for clarification

RESPONSE FORMAT:
- Be concise but complete
- Use bullet points for multiple items
- Include source citations like [Source: Title]`;

const CONVERSATIONAL_RAG_PROMPT = `You are a helpful assistant with access to a knowledge base about ${topic}.

RULES:
1. Prioritize information from the provided context
2. You may use general knowledge to provide context or explanations
3. Clearly distinguish between information from documents and general knowledge
4. If unsure, prefer saying "Based on the documents..." or "Generally speaking..."
5. Be conversational while staying accurate`;
```

### System Prompt Selection

| Use Case | Prompt Type | Hallucination Risk |
|----------|-------------|-------------------|
| Factual Q&A | Strict | Very low |
| Customer support | Strict | Very low |
| Research assistant | Conversational | Medium |
| Creative writing | Open | High (acceptable) |

## Chat Logging with Source Attribution

Track conversations with source information for debugging and analytics:

```typescript
interface ChatMessage {
  id: string;
  sessionId: string;
  role: 'user' | 'assistant';
  content: string;
  sources?: Source[];
  timestamp: number;
}

interface Source {
  chunkId: string;
  title: string;
  score: number;
  excerpt: string;
}

export async function logChat(
  env: Env,
  message: ChatMessage
): Promise<void> {
  await env.DATABASE
    .prepare(`
      INSERT INTO chat_logs (id, session_id, role, content, sources, created_at)
      VALUES (?, ?, ?, ?, ?, ?)
    `)
    .bind(
      message.id,
      message.sessionId,
      message.role,
      message.content,
      message.sources ? JSON.stringify(message.sources) : null,
      message.timestamp
    )
    .run();
}

// Complete RAG query with logging
export async function ragQueryWithLogging(
  question: string,
  sessionId: string,
  store: DocumentStore,
  env: Env
): Promise<{ answer: string; sources: Source[] }> {
  // Log user question
  await logChat(env, {
    id: crypto.randomUUID(),
    sessionId,
    role: 'user',
    content: question,
    timestamp: Date.now()
  });

  // Generate embedding
  const embedding = await env.AI.run('@cf/baai/bge-base-en-v1.5', {
    text: [question]
  }) as { data: number[][] };

  // Query vectors
  const matches = await store.queryVectors(embedding.data[0], 5);

  // Get chunk details
  const chunkIds = matches.map(m => m.id);
  const chunks = await store.getChunksWithMetadata(chunkIds);

  // Build sources
  const sources: Source[] = chunks.map((chunk, i) => ({
    chunkId: chunk.id,
    title: chunk.title,
    score: matches[i].score,
    excerpt: chunk.text.slice(0, 200) + '...'
  }));

  // Build context
  const context = chunks.map(c => c.text).join('\n\n');

  // Generate answer
  const response = await env.AI.run('@cf/meta/llama-3.1-8b-instruct', {
    messages: [
      { role: 'system', content: STRICT_RAG_SYSTEM_PROMPT },
      { role: 'user', content: `Context:\n${context}\n\nQuestion: ${question}` }
    ],
    temperature: 0.3
  });

  const answer = response.response;

  // Log assistant response with sources
  await logChat(env, {
    id: crypto.randomUUID(),
    sessionId,
    role: 'assistant',
    content: answer,
    sources,
    timestamp: Date.now()
  });

  return { answer, sources };
}
```

## Hybrid Search Pattern

Combine vector similarity with keyword matching:

```typescript
interface HybridSearchResult {
  chunkId: string;
  vectorScore: number;
  keywordScore: number;
  combinedScore: number;
}

export async function hybridSearch(
  query: string,
  embedding: number[],
  store: DocumentStore,
  env: Env,
  options: { vectorWeight?: number; keywordWeight?: number; topK?: number } = {}
): Promise<HybridSearchResult[]> {
  const {
    vectorWeight = 0.7,
    keywordWeight = 0.3,
    topK = 10
  } = options;

  // Vector search
  const vectorResults = await store.queryVectors(embedding, topK * 2);

  // Keyword search (using D1 FTS if available, or LIKE)
  const keywords = query.toLowerCase().split(/\s+/).filter(w => w.length > 2);
  const keywordPattern = keywords.map(k => `%${k}%`).join(' OR text LIKE ');

  const { results: keywordResults } = await env.DATABASE
    .prepare(`
      SELECT id, text,
        (LENGTH(text) - LENGTH(REPLACE(LOWER(text), ?, ''))) / LENGTH(?) as keyword_score
      FROM chunks
      WHERE text LIKE ?
      ORDER BY keyword_score DESC
      LIMIT ?
    `)
    .bind(keywords[0], keywords[0], `%${keywords[0]}%`, topK * 2)
    .all();

  // Merge results
  const resultMap = new Map<string, HybridSearchResult>();

  for (const vr of vectorResults) {
    resultMap.set(vr.id, {
      chunkId: vr.id,
      vectorScore: vr.score,
      keywordScore: 0,
      combinedScore: vr.score * vectorWeight
    });
  }

  for (const kr of keywordResults || []) {
    const existing = resultMap.get(kr.id);
    const normalizedKeywordScore = Math.min(kr.keyword_score / 5, 1); // Normalize

    if (existing) {
      existing.keywordScore = normalizedKeywordScore;
      existing.combinedScore += normalizedKeywordScore * keywordWeight;
    } else {
      resultMap.set(kr.id, {
        chunkId: kr.id,
        vectorScore: 0,
        keywordScore: normalizedKeywordScore,
        combinedScore: normalizedKeywordScore * keywordWeight
      });
    }
  }

  // Sort by combined score and take top K
  return Array.from(resultMap.values())
    .sort((a, b) => b.combinedScore - a.combinedScore)
    .slice(0, topK);
}
```

## Reranking with LLM

Use a second LLM pass to improve relevance:

```typescript
export async function rerankWithLLM(
  question: string,
  candidates: ChunkWithMetadata[],
  env: Env,
  topK: number = 3
): Promise<ChunkWithMetadata[]> {
  const reranked: Array<{ chunk: ChunkWithMetadata; score: number }> = [];

  for (const chunk of candidates) {
    const response = await env.AI.run('@cf/meta/llama-3.1-8b-instruct', {
      messages: [{
        role: 'user',
        content: `Rate the relevance of this passage to answering the question.
Score from 0-10 where 10 is highly relevant.
Return ONLY a number.

Question: ${question}

Passage: ${chunk.text.slice(0, 500)}

Score:`
      }],
      max_tokens: 5,
      temperature: 0
    });

    const score = parseInt(response.response.trim()) || 0;
    reranked.push({ chunk, score });
  }

  return reranked
    .sort((a, b) => b.score - a.score)
    .slice(0, topK)
    .map(r => r.chunk);
}
```

## Performance Optimization

### Batching Embeddings

```typescript
const BATCH_SIZE = 10;

export async function batchGenerateEmbeddings(
  texts: string[],
  env: Env
): Promise<number[][]> {
  const embeddings: number[][] = [];

  for (let i = 0; i < texts.length; i += BATCH_SIZE) {
    const batch = texts.slice(i, i + BATCH_SIZE);
    const result = await env.AI.run('@cf/baai/bge-base-en-v1.5', {
      text: batch
    }) as { data: number[][] };
    embeddings.push(...result.data);
  }

  return embeddings;
}
```

### Caching Embeddings

```typescript
export async function getCachedEmbedding(
  text: string,
  env: Env
): Promise<number[]> {
  const hash = await crypto.subtle.digest(
    'SHA-256',
    new TextEncoder().encode(text)
  );
  const cacheKey = `emb:${Buffer.from(hash).toString('hex').slice(0, 16)}`;

  // Check cache
  const cached = await env.CACHE.get(cacheKey, 'json');
  if (cached) return cached as number[];

  // Generate embedding
  const result = await env.AI.run('@cf/baai/bge-base-en-v1.5', {
    text: [text]
  }) as { data: number[][] };

  // Cache for 24 hours
  await env.CACHE.put(cacheKey, JSON.stringify(result.data[0]), {
    expirationTtl: 86400
  });

  return result.data[0];
}
```

## Database Schema

```sql
-- Documents table
CREATE TABLE documents (
  id TEXT PRIMARY KEY,
  article_id TEXT NOT NULL,
  title TEXT NOT NULL,
  metadata TEXT,  -- JSON
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL
);

-- Chunks table
CREATE TABLE chunks (
  id TEXT PRIMARY KEY,
  document_id TEXT NOT NULL,
  text TEXT NOT NULL,
  chunk_index INTEGER NOT NULL,
  metadata TEXT,  -- JSON
  created_at INTEGER NOT NULL,
  FOREIGN KEY (document_id) REFERENCES documents(id)
);

-- Chat logs table
CREATE TABLE chat_logs (
  id TEXT PRIMARY KEY,
  session_id TEXT NOT NULL,
  role TEXT NOT NULL,
  content TEXT NOT NULL,
  sources TEXT,  -- JSON array
  created_at INTEGER NOT NULL
);

-- Indexes
CREATE INDEX idx_chunks_document ON chunks(document_id);
CREATE INDEX idx_chat_session ON chat_logs(session_id);
CREATE INDEX idx_chat_created ON chat_logs(created_at);
```

## Monitoring Patterns

Track RAG quality metrics:

```typescript
interface RAGMetrics {
  queryLatency: number;
  embeddingLatency: number;
  vectorSearchLatency: number;
  generationLatency: number;
  topKScores: number[];
  chunkCount: number;
}

export async function trackRAGMetrics(
  metrics: RAGMetrics,
  env: Env
): Promise<void> {
  // Log to console for observability
  console.log(JSON.stringify({
    type: 'rag_metrics',
    ...metrics,
    avgTopKScore: metrics.topKScores.reduce((a, b) => a + b, 0) / metrics.topKScores.length
  }));

  // Optional: Store in D1 for analysis
  await env.DATABASE
    .prepare(`
      INSERT INTO rag_metrics (query_latency, avg_score, chunk_count, created_at)
      VALUES (?, ?, ?, ?)
    `)
    .bind(
      metrics.queryLatency,
      metrics.topKScores[0] || 0,
      metrics.chunkCount,
      Date.now()
    )
    .run();
}
```
