# RAG (Retrieval-Augmented Generation) Best Practices

## Official Documentation
- **LangChain**: https://python.langchain.com/docs/get_started/introduction
- **LlamaIndex**: https://docs.llamaindex.ai/en/stable
- **Haystack**: https://haystack.deepset.ai/overview/intro
- **ChromaDB**: https://docs.trychroma.com
- **Pinecone**: https://docs.pinecone.io
- **Weaviate**: https://weaviate.io/developers/weaviate
- **ToolFront**: https://github.com/kruskal-labs/toolfront

## Overview

RAG combines retrieval-based and generative approaches to provide more accurate, contextual, and up-to-date responses by retrieving relevant information from external knowledge bases before generating answers.

## Architecture Components

### Core RAG Pipeline
```python
# Basic RAG pipeline structure
class RAGPipeline:
    def __init__(self, retriever, generator, embedder):
        self.retriever = retriever
        self.generator = generator
        self.embedder = embedder
    
    def query(self, question: str) -> str:
        # 1. Embed the question
        question_embedding = self.embedder.embed(question)
        
        # 2. Retrieve relevant documents
        relevant_docs = self.retriever.retrieve(question_embedding, top_k=5)
        
        # 3. Format context
        context = self.format_context(relevant_docs)
        
        # 4. Generate response
        response = self.generator.generate(question, context)
        
        return response
    
    def format_context(self, documents: list) -> str:
        return "\n\n".join([doc.content for doc in documents])
```

## Popular RAG Libraries

### 1. LangChain
```python
# Installation
# pip install langchain langchain-openai langchain-chroma

from langchain.document_loaders import TextLoader, PDFLoader, WebBaseLoader
from langchain.text_splitter import RecursiveCharacterTextSplitter
from langchain.embeddings import OpenAIEmbeddings
from langchain.vectorstores import Chroma
from langchain.llms import OpenAI
from langchain.chains import RetrievalQA
from langchain.prompts import PromptTemplate

# Document Processing
def setup_document_store(file_paths):
    # Load documents
    documents = []
    for file_path in file_paths:
        if file_path.endswith('.pdf'):
            loader = PDFLoader(file_path)
        elif file_path.endswith('.txt'):
            loader = TextLoader(file_path)
        else:
            loader = WebBaseLoader(file_path)
        documents.extend(loader.load())
    
    # Split documents into chunks
    text_splitter = RecursiveCharacterTextSplitter(
        chunk_size=1000,
        chunk_overlap=200,
        length_function=len,
        separators=["\n\n", "\n", " ", ""]
    )
    chunks = text_splitter.split_documents(documents)
    
    # Create embeddings and vector store
    embeddings = OpenAIEmbeddings(
        openai_api_key="your-api-key",
        model="text-embedding-ada-002"
    )
    
    vectorstore = Chroma.from_documents(
        documents=chunks,
        embedding=embeddings,
        persist_directory="./chroma_db"
    )
    
    return vectorstore

# RAG Chain Setup
def create_rag_chain(vectorstore):
    # Custom prompt template
    prompt_template = """
    Use the following pieces of context to answer the question at the end. 
    If you don't know the answer, just say that you don't know, don't try to make up an answer.
    
    Context: {context}
    
    Question: {question}
    
    Answer:"""
    
    PROMPT = PromptTemplate(
        template=prompt_template,
        input_variables=["context", "question"]
    )
    
    # Create retrieval chain
    qa_chain = RetrievalQA.from_chain_type(
        llm=OpenAI(temperature=0),
        chain_type="stuff",
        retriever=vectorstore.as_retriever(search_kwargs={"k": 3}),
        chain_type_kwargs={"prompt": PROMPT},
        return_source_documents=True
    )
    
    return qa_chain

# Usage example
vectorstore = setup_document_store([
    "documents/manual.pdf",
    "documents/faq.txt",
    "https://example.com/documentation"
])

qa_chain = create_rag_chain(vectorstore)

# Query the system
result = qa_chain({"query": "How do I configure the system?"})
print(f"Answer: {result['result']}")
print(f"Sources: {[doc.metadata.get('source', 'Unknown') for doc in result['source_documents']]}")
```

### 2. LlamaIndex
```python
# Installation
# pip install llama-index llama-index-embeddings-openai llama-index-llms-openai

from llama_index.core import VectorStoreIndex, SimpleDirectoryReader, Settings
from llama_index.embeddings.openai import OpenAIEmbedding
from llama_index.llms.openai import OpenAI
from llama_index.core.node_parser import SentenceSplitter
from llama_index.core.retrievers import VectorIndexRetriever
from llama_index.core.query_engine import RetrieverQueryEngine
from llama_index.core.postprocessor import SimilarityPostprocessor

# Configure global settings
Settings.llm = OpenAI(model="gpt-3.5-turbo", temperature=0.1)
Settings.embed_model = OpenAIEmbedding(model="text-embedding-ada-002")

# Document loading and indexing
def create_index(data_directory: str):
    # Load documents
    documents = SimpleDirectoryReader(data_directory).load_data()
    
    # Configure text splitter
    text_splitter = SentenceSplitter(
        chunk_size=1024,
        chunk_overlap=20
    )
    Settings.text_splitter = text_splitter
    
    # Create index
    index = VectorStoreIndex.from_documents(
        documents,
        show_progress=True
    )
    
    # Persist index
    index.storage_context.persist(persist_dir="./storage")
    
    return index

# Advanced RAG with custom retriever
def create_advanced_rag_engine(index):
    # Configure retriever
    retriever = VectorIndexRetriever(
        index=index,
        similarity_top_k=5
    )
    
    # Configure postprocessor
    postprocessor = SimilarityPostprocessor(similarity_cutoff=0.7)
    
    # Create query engine
    query_engine = RetrieverQueryEngine(
        retriever=retriever,
        node_postprocessors=[postprocessor]
    )
    
    return query_engine

# Usage
index = create_index("./data")
query_engine = create_advanced_rag_engine(index)

response = query_engine.query("What are the key features of the product?")
print(f"Response: {response}")

# Get source nodes
for node in response.source_nodes:
    print(f"Score: {node.score:.2f}")
    print(f"Text: {node.text[:200]}...")
    print("---")
```

### 3. Haystack
```python
# Installation
# pip install farm-haystack[inference] sentence-transformers

from haystack import Document, Pipeline
from haystack.components.retrievers.in_memory import InMemoryBM25Retriever
from haystack.components.generators import OpenAIGenerator
from haystack.components.builders.answer_builder import AnswerBuilder
from haystack.components.builders.prompt_builder import PromptBuilder
from haystack.document_stores.in_memory import InMemoryDocumentStore

# Setup document store
def setup_haystack_rag(documents_data):
    # Create documents
    documents = [
        Document(content=text, meta={"source": source})
        for text, source in documents_data
    ]
    
    # Initialize document store and add documents
    document_store = InMemoryDocumentStore()
    document_store.write_documents(documents)
    
    # Create components
    retriever = InMemoryBM25Retriever(document_store=document_store)
    
    prompt_template = """
    Given these documents, answer the question.
    Documents:
    {% for doc in documents %}
        {{ doc.content }}
    {% endfor %}
    
    Question: {{ question }}
    Answer:
    """
    
    prompt_builder = PromptBuilder(template=prompt_template)
    generator = OpenAIGenerator(model="gpt-3.5-turbo")
    
    # Create pipeline
    rag_pipeline = Pipeline()
    rag_pipeline.add_component("retriever", retriever)
    rag_pipeline.add_component("prompt_builder", prompt_builder)
    rag_pipeline.add_component("llm", generator)
    
    # Connect components
    rag_pipeline.connect("retriever", "prompt_builder.documents")
    rag_pipeline.connect("prompt_builder", "llm")
    
    return rag_pipeline

# Usage
documents_data = [
    ("Python is a programming language", "doc1"),
    ("RAG combines retrieval and generation", "doc2"),
    ("Vector databases store embeddings", "doc3")
]

pipeline = setup_haystack_rag(documents_data)

result = pipeline.run({
    "retriever": {"query": "What is Python?"},
    "prompt_builder": {"question": "What is Python?"}
})

print(result["llm"]["replies"][0])
```

### 4. ChromaDB Integration
```python
# Installation
# pip install chromadb

import chromadb
from chromadb.config import Settings
import openai
from typing import List

class ChromaRAGSystem:
    def __init__(self, collection_name: str = "documents"):
        # Initialize ChromaDB client
        self.client = chromadb.PersistentClient(
            path="./chroma_db",
            settings=Settings(anonymized_telemetry=False)
        )
        
        # Get or create collection
        self.collection = self.client.get_or_create_collection(
            name=collection_name,
            metadata={"hnsw:space": "cosine"}
        )
        
        # Initialize OpenAI
        openai.api_key = "your-openai-api-key"
    
    def add_documents(self, texts: List[str], metadatas: List[dict], ids: List[str]):
        """Add documents to the vector store"""
        self.collection.add(
            documents=texts,
            metadatas=metadatas,
            ids=ids
        )
    
    def retrieve(self, query: str, n_results: int = 5):
        """Retrieve relevant documents"""
        results = self.collection.query(
            query_texts=[query],
            n_results=n_results,
            include=["documents", "metadatas", "distances"]
        )
        return results
    
    def generate_response(self, query: str, context: str) -> str:
        """Generate response using OpenAI"""
        prompt = f"""
        Context: {context}
        
        Question: {query}
        
        Based on the context provided, please answer the question. If the answer is not in the context, say so.
        
        Answer:
        """
        
        response = openai.ChatCompletion.create(
            model="gpt-3.5-turbo",
            messages=[{"role": "user", "content": prompt}],
            temperature=0.1,
            max_tokens=500
        )
        
        return response.choices[0].message.content
    
    def query(self, question: str) -> dict:
        """Main RAG query method"""
        # Retrieve relevant documents
        results = self.retrieve(question)
        
        # Format context
        context = "\n\n".join(results['documents'][0])
        
        # Generate response
        answer = self.generate_response(question, context)
        
        return {
            "answer": answer,
            "sources": results['metadatas'][0],
            "distances": results['distances'][0]
        }

# Usage
rag_system = ChromaRAGSystem("knowledge_base")

# Add documents
documents = [
    "Machine learning is a subset of artificial intelligence.",
    "RAG systems combine retrieval and generation for better responses.",
    "Vector databases enable semantic search capabilities."
]

metadatas = [
    {"source": "ml_basics.txt", "topic": "machine_learning"},
    {"source": "rag_guide.txt", "topic": "rag"},
    {"source": "vector_db.txt", "topic": "databases"}
]

ids = ["doc1", "doc2", "doc3"]

rag_system.add_documents(documents, metadatas, ids)

# Query the system
result = rag_system.query("What is machine learning?")
print(f"Answer: {result['answer']}")
print(f"Sources: {[meta['source'] for meta in result['sources']]}")
```

## Document Processing Best Practices

### Text Chunking Strategies
```python
from langchain.text_splitter import (
    RecursiveCharacterTextSplitter,
    TokenTextSplitter,
    SpacyTextSplitter
)

class AdvancedChunking:
    def __init__(self):
        self.strategies = {
            'recursive': RecursiveCharacterTextSplitter(
                chunk_size=1000,
                chunk_overlap=200,
                length_function=len,
                separators=["\n\n", "\n", " ", ""]
            ),
            'token_based': TokenTextSplitter(
                chunk_size=512,
                chunk_overlap=50,
                encoding_name="cl100k_base"  # GPT-4 encoding
            ),
            'semantic': SpacyTextSplitter(
                chunk_size=1000,
                chunk_overlap=200,
                separator=" "
            )
        }
    
    def chunk_document(self, text: str, strategy: str = 'recursive'):
        """Chunk document using specified strategy"""
        splitter = self.strategies.get(strategy, self.strategies['recursive'])
        chunks = splitter.split_text(text)
        
        # Add metadata to chunks
        processed_chunks = []
        for i, chunk in enumerate(chunks):
            processed_chunks.append({
                'content': chunk,
                'chunk_id': i,
                'strategy': strategy,
                'length': len(chunk),
                'tokens': len(chunk.split())
            })
        
        return processed_chunks
    
    def adaptive_chunking(self, text: str, max_tokens: int = 512):
        """Adaptive chunking based on content structure"""
        paragraphs = text.split('\n\n')
        chunks = []
        current_chunk = ""
        
        for paragraph in paragraphs:
            # Rough token estimation (1 token ≈ 4 characters)
            estimated_tokens = len(current_chunk + paragraph) / 4
            
            if estimated_tokens > max_tokens and current_chunk:
                chunks.append(current_chunk.strip())
                current_chunk = paragraph
            else:
                current_chunk += "\n\n" + paragraph if current_chunk else paragraph
        
        if current_chunk:
            chunks.append(current_chunk.strip())
        
        return chunks

# Usage
chunker = AdvancedChunking()
chunks = chunker.chunk_document(document_text, strategy='recursive')
adaptive_chunks = chunker.adaptive_chunking(document_text, max_tokens=400)
```

### Metadata Enhancement
```python
import re
from datetime import datetime
from typing import Dict, Any

class MetadataExtractor:
    def __init__(self):
        self.patterns = {
            'email': r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b',
            'phone': r'\b\d{3}-\d{3}-\d{4}\b|\b\(\d{3}\)\s\d{3}-\d{4}\b',
            'date': r'\b\d{1,2}/\d{1,2}/\d{4}\b|\b\d{4}-\d{2}-\d{2}\b',
            'url': r'https?://(?:[-\w.])+(?:[:\d]+)?(?:/(?:[\w/_.])*(?:\?(?:[\w&=%.])*)?(?:#(?:[\w.])*)?)?'
        }
    
    def extract_metadata(self, text: str, source: str = None) -> Dict[str, Any]:
        """Extract comprehensive metadata from text"""
        metadata = {
            'source': source,
            'length': len(text),
            'word_count': len(text.split()),
            'paragraph_count': len(text.split('\n\n')),
            'extracted_at': datetime.now().isoformat(),
            'contains': {}
        }
        
        # Extract patterns
        for pattern_name, pattern in self.patterns.items():
            matches = re.findall(pattern, text)
            metadata['contains'][pattern_name] = len(matches) > 0
            if matches:
                metadata[f'{pattern_name}_examples'] = matches[:3]  # Store first 3 matches
        
        # Extract key phrases (simplified)
        words = text.lower().split()
        word_freq = {}
        for word in words:
            if len(word) > 3 and word.isalpha():
                word_freq[word] = word_freq.get(word, 0) + 1
        
        # Get top keywords
        top_keywords = sorted(word_freq.items(), key=lambda x: x[1], reverse=True)[:10]
        metadata['keywords'] = [word for word, freq in top_keywords]
        
        return metadata

# Document processing with rich metadata
def process_documents_with_metadata(file_paths: list):
    extractor = MetadataExtractor()
    chunker = AdvancedChunking()
    processed_docs = []
    
    for file_path in file_paths:
        # Load document
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
        
        # Extract metadata
        doc_metadata = extractor.extract_metadata(content, source=file_path)
        
        # Chunk document
        chunks = chunker.chunk_document(content)
        
        # Add metadata to each chunk
        for chunk_data in chunks:
            chunk_metadata = {**doc_metadata, **chunk_data}
            processed_docs.append({
                'content': chunk_data['content'],
                'metadata': chunk_metadata
            })
    
    return processed_docs
```

## Vector Store Optimization

### Embedding Strategies
```python
from sentence_transformers import SentenceTransformer
import numpy as np
from typing import List

class EmbeddingManager:
    def __init__(self, model_name: str = "all-MiniLM-L6-v2"):
        self.model = SentenceTransformer(model_name)
        self.embedding_cache = {}
    
    def embed_texts(self, texts: List[str], use_cache: bool = True) -> np.ndarray:
        """Generate embeddings with caching"""
        if use_cache:
            cached_embeddings = []
            uncached_texts = []
            uncached_indices = []
            
            for i, text in enumerate(texts):
                if text in self.embedding_cache:
                    cached_embeddings.append((i, self.embedding_cache[text]))
                else:
                    uncached_texts.append(text)
                    uncached_indices.append(i)
            
            # Generate embeddings for uncached texts
            if uncached_texts:
                new_embeddings = self.model.encode(uncached_texts)
                for text, embedding in zip(uncached_texts, new_embeddings):
                    self.embedding_cache[text] = embedding
            
            # Combine cached and new embeddings
            all_embeddings = [None] * len(texts)
            for i, embedding in cached_embeddings:
                all_embeddings[i] = embedding
            
            for i, idx in enumerate(uncached_indices):
                all_embeddings[idx] = new_embeddings[i]
            
            return np.array(all_embeddings)
        else:
            return self.model.encode(texts)
    
    def find_optimal_chunk_size(self, texts: List[str], sizes: List[int] = None):
        """Find optimal chunk size for embeddings"""
        if sizes is None:
            sizes = [256, 512, 1024, 2048]
        
        results = {}
        for size in sizes:
            chunked_texts = []
            for text in texts:
                if len(text) > size:
                    # Simple chunking for testing
                    chunks = [text[i:i+size] for i in range(0, len(text), size)]
                    chunked_texts.extend(chunks)
                else:
                    chunked_texts.append(text)
            
            embeddings = self.embed_texts(chunked_texts, use_cache=False)
            
            # Calculate embedding quality metrics
            avg_magnitude = np.mean(np.linalg.norm(embeddings, axis=1))
            embedding_variance = np.var(embeddings)
            
            results[size] = {
                'chunk_count': len(chunked_texts),
                'avg_magnitude': avg_magnitude,
                'variance': embedding_variance,
                'embedding_shape': embeddings.shape
            }
        
        return results

# Usage
embedding_manager = EmbeddingManager("all-mpnet-base-v2")
texts = ["Your document texts here..."]
embeddings = embedding_manager.embed_texts(texts)

# Find optimal chunk size
optimization_results = embedding_manager.find_optimal_chunk_size(texts)
for size, metrics in optimization_results.items():
    print(f"Chunk size {size}: {metrics}")
```

### Hybrid Search Implementation
```python
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.metrics.pairwise import cosine_similarity
import numpy as np

class HybridRetriever:
    def __init__(self, alpha: float = 0.7):
        """
        alpha: weight for semantic similarity (1-alpha for keyword similarity)
        """
        self.alpha = alpha
        self.embedding_model = SentenceTransformer("all-MiniLM-L6-v2")
        self.tfidf_vectorizer = TfidfVectorizer(
            max_features=5000,
            stop_words='english',
            ngram_range=(1, 2)
        )
        self.documents = []
        self.embeddings = None
        self.tfidf_matrix = None
    
    def add_documents(self, documents: List[str]):
        """Add documents to the retriever"""
        self.documents = documents
        
        # Generate embeddings
        self.embeddings = self.embedding_model.encode(documents)
        
        # Generate TF-IDF vectors
        self.tfidf_matrix = self.tfidf_vectorizer.fit_transform(documents)
    
    def retrieve(self, query: str, top_k: int = 5):
        """Retrieve documents using hybrid search"""
        if not self.documents:
            return []
        
        # Semantic similarity
        query_embedding = self.embedding_model.encode([query])
        semantic_scores = cosine_similarity(query_embedding, self.embeddings)[0]
        
        # Keyword similarity
        query_tfidf = self.tfidf_vectorizer.transform([query])
        keyword_scores = cosine_similarity(query_tfidf, self.tfidf_matrix)[0]
        
        # Combine scores
        combined_scores = (
            self.alpha * semantic_scores + 
            (1 - self.alpha) * keyword_scores
        )
        
        # Get top-k results
        top_indices = np.argsort(combined_scores)[::-1][:top_k]
        
        results = []
        for idx in top_indices:
            results.append({
                'document': self.documents[idx],
                'score': combined_scores[idx],
                'semantic_score': semantic_scores[idx],
                'keyword_score': keyword_scores[idx],
                'index': idx
            })
        
        return results

# Usage
retriever = HybridRetriever(alpha=0.7)
retriever.add_documents([
    "Machine learning algorithms learn from data",
    "Deep learning uses neural networks with multiple layers",
    "Natural language processing handles text data"
])

results = retriever.retrieve("What is deep learning?", top_k=3)
for result in results:
    print(f"Score: {result['score']:.3f} - {result['document'][:100]}...")
```

## Advanced RAG Patterns

### Multi-hop Reasoning
```python
class MultiHopRAG:
    def __init__(self, retriever, generator):
        self.retriever = retriever
        self.generator = generator
        self.max_hops = 3
    
    def multi_hop_query(self, initial_query: str):
        """Perform multi-hop reasoning"""
        current_query = initial_query
        context_history = []
        
        for hop in range(self.max_hops):
            # Retrieve documents for current query
            documents = self.retriever.retrieve(current_query)
            context_history.extend(documents)
            
            # Generate intermediate answer and next question
            context = "\n".join([doc['content'] for doc in documents])
            
            prompt = f"""
            Based on the context below, answer the question and identify if you need more information.
            
            Context: {context}
            Question: {current_query}
            
            If you can answer completely, provide the answer.
            If you need more information, provide:
            1. Partial answer (if any)
            2. Next question to ask
            
            Format:
            ANSWER: [your answer or "INCOMPLETE"]
            NEXT_QUESTION: [next question or "NONE"]
            """
            
            response = self.generator.generate(prompt)
            
            # Parse response
            if "NEXT_QUESTION: NONE" in response:
                break
            
            # Extract next question for next hop
            next_question_start = response.find("NEXT_QUESTION:") + len("NEXT_QUESTION:")
            current_query = response[next_question_start:].strip()
            
            if not current_query or current_query == "NONE":
                break
        
        # Generate final answer
        all_context = "\n\n".join([doc['content'] for doc in context_history])
        final_prompt = f"""
        Based on all the gathered context, provide a comprehensive answer to: {initial_query}
        
        Context: {all_context}
        
        Answer:
        """
        
        final_answer = self.generator.generate(final_prompt)
        
        return {
            'answer': final_answer,
            'hops': hop + 1,
            'sources': context_history
        }
```

### Query Expansion and Rewriting
```python
from transformers import pipeline
import re

class QueryProcessor:
    def __init__(self):
        self.question_generator = pipeline(
            "text2text-generation",
            model="google/flan-t5-base"
        )
    
    def expand_query(self, query: str) -> List[str]:
        """Generate multiple variations of the query"""
        expansion_prompts = [
            f"Rephrase this question: {query}",
            f"Ask the same question differently: {query}",
            f"What is another way to ask: {query}?",
            f"Simplify this question: {query}",
            f"Make this question more specific: {query}"
        ]
        
        expanded_queries = [query]  # Include original
        
        for prompt in expansion_prompts:
            try:
                result = self.question_generator(prompt, max_length=100, num_return_sequences=1)
                expanded_query = result[0]['generated_text'].strip()
                if expanded_query and expanded_query not in expanded_queries:
                    expanded_queries.append(expanded_query)
            except Exception as e:
                print(f"Error in query expansion: {e}")
                continue
        
        return expanded_queries
    
    def extract_keywords(self, query: str) -> List[str]:
        """Extract important keywords from query"""
        # Remove stop words and extract meaningful terms
        stop_words = {
            'what', 'is', 'are', 'how', 'when', 'where', 'why', 'who',
            'the', 'a', 'an', 'and', 'or', 'but', 'in', 'on', 'at',
            'to', 'for', 'of', 'with', 'by', 'about', 'can', 'could',
            'would', 'should', 'do', 'does', 'did', 'will', 'have', 'has'
        }
        
        # Simple keyword extraction
        words = re.findall(r'\b\w+\b', query.lower())
        keywords = [word for word in words if word not in stop_words and len(word) > 2]
        
        return keywords
    
    def rewrite_query_for_retrieval(self, query: str) -> str:
        """Rewrite query to be more suitable for retrieval"""
        keywords = self.extract_keywords(query)
        
        # Create a more retrieval-friendly version
        if len(keywords) >= 2:
            return " ".join(keywords[:5])  # Top 5 keywords
        else:
            return query

# Enhanced RAG with query processing
class EnhancedRAG:
    def __init__(self, retriever, generator):
        self.retriever = retriever
        self.generator = generator
        self.query_processor = QueryProcessor()
    
    def query_with_expansion(self, query: str, top_k: int = 5):
        """Query with automatic expansion"""
        # Expand query
        expanded_queries = self.query_processor.expand_query(query)
        
        # Retrieve documents for all query variations
        all_documents = []
        seen_docs = set()
        
        for expanded_query in expanded_queries:
            rewritten_query = self.query_processor.rewrite_query_for_retrieval(expanded_query)
            docs = self.retriever.retrieve(rewritten_query, top_k=top_k)
            
            for doc in docs:
                doc_hash = hash(doc['content'][:100])  # Simple deduplication
                if doc_hash not in seen_docs:
                    seen_docs.add(doc_hash)
                    doc['query_variant'] = expanded_query
                    all_documents.append(doc)
        
        # Rank and select best documents
        sorted_docs = sorted(all_documents, key=lambda x: x['score'], reverse=True)
        top_docs = sorted_docs[:top_k]
        
        # Generate answer
        context = "\n\n".join([doc['content'] for doc in top_docs])
        answer = self.generator.generate(query, context)
        
        return {
            'answer': answer,
            'sources': top_docs,
            'expanded_queries': expanded_queries
        }
```

## Production Deployment

### Scalable RAG Service
```python
from fastapi import FastAPI, HTTPException, BackgroundTasks
from pydantic import BaseModel
import asyncio
import logging
from typing import Optional
import redis
import json

app = FastAPI(title="RAG Service API")

# Setup logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Redis for caching
redis_client = redis.Redis(host='localhost', port=6379, db=0)

class QueryRequest(BaseModel):
    question: str
    top_k: Optional[int] = 5
    use_cache: Optional[bool] = True
    max_tokens: Optional[int] = 500

class QueryResponse(BaseModel):
    answer: str
    sources: list
    processing_time: float
    cached: bool

class RAGService:
    def __init__(self):
        # Initialize your RAG components here
        self.retriever = None  # Your retriever
        self.generator = None  # Your generator
        self.cache_ttl = 3600  # 1 hour
    
    async def initialize(self):
        """Initialize RAG components asynchronously"""
        # Load models and setup components
        logger.info("Initializing RAG service...")
        # self.retriever = setup_retriever()
        # self.generator = setup_generator()
    
    async def query(self, request: QueryRequest) -> QueryResponse:
        """Process RAG query"""
        import time
        start_time = time.time()
        
        # Check cache
        cached_result = None
        if request.use_cache:
            cache_key = f"rag:{hash(request.question + str(request.top_k))}"
            cached_result = redis_client.get(cache_key)
        
        if cached_result:
            result = json.loads(cached_result)
            result['processing_time'] = time.time() - start_time
            result['cached'] = True
            return QueryResponse(**result)
        
        # Process query
        try:
            # Retrieve documents
            documents = await self.async_retrieve(request.question, request.top_k)
            
            # Generate answer
            answer = await self.async_generate(request.question, documents, request.max_tokens)
            
            result = {
                'answer': answer,
                'sources': [{'content': doc['content'][:200], 'score': doc['score']} for doc in documents],
                'processing_time': time.time() - start_time,
                'cached': False
            }
            
            # Cache result
            if request.use_cache:
                redis_client.setex(cache_key, self.cache_ttl, json.dumps(result))
            
            return QueryResponse(**result)
            
        except Exception as e:
            logger.error(f"Error processing query: {e}")
            raise HTTPException(status_code=500, detail="Internal processing error")
    
    async def async_retrieve(self, query: str, top_k: int):
        """Async document retrieval"""
        # Implement async retrieval
        return await asyncio.to_thread(self.retriever.retrieve, query, top_k)
    
    async def async_generate(self, query: str, documents: list, max_tokens: int):
        """Async answer generation"""
        context = "\n".join([doc['content'] for doc in documents])
        # Implement async generation
        return await asyncio.to_thread(self.generator.generate, query, context, max_tokens)

# Initialize service
rag_service = RAGService()

@app.on_event("startup")
async def startup_event():
    await rag_service.initialize()

@app.post("/query", response_model=QueryResponse)
async def query_endpoint(request: QueryRequest):
    """Main query endpoint"""
    return await rag_service.query(request)

@app.post("/add_documents")
async def add_documents(documents: list, background_tasks: BackgroundTasks):
    """Add documents to the knowledge base"""
    background_tasks.add_task(index_documents, documents)
    return {"message": "Documents queued for indexing"}

@app.get("/health")
async def health_check():
    """Health check endpoint"""
    return {"status": "healthy", "service": "rag-api"}

def index_documents(documents: list):
    """Background task to index documents"""
    logger.info(f"Indexing {len(documents)} documents")
    # Implement document indexing
    
# Run with: uvicorn main:app --host 0.0.0.0 --port 8000
```

### Docker Deployment
```dockerfile
# Dockerfile
FROM python:3.9-slim

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements
COPY requirements.txt .

# Install Python dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY . .

# Create non-root user
RUN useradd -m -u 1000 raguser && chown -R raguser:raguser /app
USER raguser

# Expose port
EXPOSE 8000

# Health check
HEALTHCHECK --interval=30s --timeout=30s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8000/health || exit 1

# Run the application
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
```

```yaml
# docker-compose.yml
version: '3.8'

services:
  rag-api:
    build: .
    ports:
      - "8000:8000"
    environment:
      - OPENAI_API_KEY=${OPENAI_API_KEY}
      - REDIS_URL=redis://redis:6379
    depends_on:
      - redis
      - chroma
    volumes:
      - ./data:/app/data
      - ./models:/app/models
  
  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"
    volumes:
      - redis_data:/data
  
  chroma:
    image: chromadb/chroma:latest
    ports:
      - "8001:8000"
    volumes:
      - chroma_data:/chroma/chroma
    environment:
      - ALLOW_RESET=TRUE

volumes:
  redis_data:
  chroma_data:
```

## Monitoring and Evaluation

### RAG Performance Metrics
```python
import numpy as np
from sklearn.metrics.pairwise import cosine_similarity
from rouge_score import rouge_scorer
from bert_score import score

class RAGEvaluator:
    def __init__(self):
        self.rouge_scorer = rouge_scorer.RougeScorer(['rouge1', 'rouge2', 'rougeL'], use_stemmer=True)
    
    def evaluate_retrieval(self, retrieved_docs, relevant_docs):
        """Evaluate retrieval performance"""
        retrieved_ids = set([doc['id'] for doc in retrieved_docs])
        relevant_ids = set([doc['id'] for doc in relevant_docs])
        
        # Calculate precision, recall, F1
        intersection = retrieved_ids.intersection(relevant_ids)
        
        precision = len(intersection) / len(retrieved_ids) if retrieved_ids else 0
        recall = len(intersection) / len(relevant_ids) if relevant_ids else 0
        f1 = 2 * precision * recall / (precision + recall) if (precision + recall) > 0 else 0
        
        return {
            'precision': precision,
            'recall': recall,
            'f1': f1,
            'retrieved_count': len(retrieved_ids),
            'relevant_count': len(relevant_ids)
        }
    
    def evaluate_generation(self, generated_answer, reference_answer):
        """Evaluate generation quality"""
        # ROUGE scores
        rouge_scores = self.rouge_scorer.score(reference_answer, generated_answer)
        
        # BERT Score
        P, R, F1 = score([generated_answer], [reference_answer], lang='en')
        
        return {
            'rouge1_f1': rouge_scores['rouge1'].fmeasure,
            'rouge2_f1': rouge_scores['rouge2'].fmeasure,
            'rougeL_f1': rouge_scores['rougeL'].fmeasure,
            'bert_score_f1': F1.item()
        }
    
    def evaluate_end_to_end(self, questions, ground_truth_answers, ground_truth_docs, rag_system):
        """End-to-end RAG evaluation"""
        results = {
            'retrieval_metrics': [],
            'generation_metrics': [],
            'response_times': []
        }
        
        for i, (question, gt_answer, gt_docs) in enumerate(zip(questions, ground_truth_answers, ground_truth_docs)):
            import time
            start_time = time.time()
            
            # Get RAG response
            rag_response = rag_system.query(question)
            response_time = time.time() - start_time
            
            # Evaluate retrieval
            retrieval_metrics = self.evaluate_retrieval(rag_response['sources'], gt_docs)
            
            # Evaluate generation
            generation_metrics = self.evaluate_generation(rag_response['answer'], gt_answer)
            
            results['retrieval_metrics'].append(retrieval_metrics)
            results['generation_metrics'].append(generation_metrics)
            results['response_times'].append(response_time)
        
        # Calculate averages
        avg_results = {
            'avg_retrieval_f1': np.mean([m['f1'] for m in results['retrieval_metrics']]),
            'avg_generation_rouge1': np.mean([m['rouge1_f1'] for m in results['generation_metrics']]),
            'avg_generation_bert_score': np.mean([m['bert_score_f1'] for m in results['generation_metrics']]),
            'avg_response_time': np.mean(results['response_times'])
        }
        
        return avg_results, results

# Usage
evaluator = RAGEvaluator()
# evaluation_results = evaluator.evaluate_end_to_end(test_questions, test_answers, test_docs, rag_system)
```

### Monitoring Dashboard
```python
import streamlit as st
import plotly.express as px
import pandas as pd
from datetime import datetime, timedelta

def create_monitoring_dashboard():
    st.title("RAG System Monitoring Dashboard")
    
    # Sidebar filters
    st.sidebar.header("Filters")
    time_range = st.sidebar.selectbox("Time Range", ["1 hour", "24 hours", "7 days", "30 days"])
    
    # Mock data (replace with actual monitoring data)
    dates = pd.date_range(start=datetime.now()-timedelta(days=7), end=datetime.now(), freq='H')
    
    metrics_data = pd.DataFrame({
        'timestamp': dates,
        'query_count': np.random.poisson(10, len(dates)),
        'avg_response_time': np.random.normal(2.5, 0.5, len(dates)),
        'error_rate': np.random.exponential(0.02, len(dates)),
        'cache_hit_rate': np.random.beta(8, 2, len(dates))
    })
    
    # Key metrics
    col1, col2, col3, col4 = st.columns(4)
    
    with col1:
        st.metric("Total Queries", int(metrics_data['query_count'].sum()))
    
    with col2:
        st.metric("Avg Response Time", f"{metrics_data['avg_response_time'].mean():.2f}s")
    
    with col3:
        st.metric("Error Rate", f"{metrics_data['error_rate'].mean()*100:.2f}%")
    
    with col4:
        st.metric("Cache Hit Rate", f"{metrics_data['cache_hit_rate'].mean()*100:.1f}%")
    
    # Charts
    st.subheader("Query Volume Over Time")
    fig1 = px.line(metrics_data, x='timestamp', y='query_count', title="Queries per Hour")
    st.plotly_chart(fig1, use_container_width=True)
    
    st.subheader("Performance Metrics")
    col1, col2 = st.columns(2)
    
    with col1:
        fig2 = px.line(metrics_data, x='timestamp', y='avg_response_time', title="Average Response Time")
        st.plotly_chart(fig2, use_container_width=True)
    
    with col2:
        fig3 = px.line(metrics_data, x='timestamp', y='cache_hit_rate', title="Cache Hit Rate")
        st.plotly_chart(fig3, use_container_width=True)
    
    # Recent queries
    st.subheader("Recent Queries")
    recent_queries = pd.DataFrame({
        'timestamp': pd.date_range(start=datetime.now()-timedelta(hours=1), periods=10, freq='6min'),
        'query': [f"Sample query {i+1}" for i in range(10)],
        'response_time': np.random.normal(2.5, 0.5, 10),
        'status': np.random.choice(['success', 'error'], 10, p=[0.95, 0.05])
    })
    
    st.dataframe(recent_queries, use_container_width=True)

if __name__ == "__main__":
    create_monitoring_dashboard()
```

## Common Pitfalls and Solutions

### 1. Chunking Strategy Issues
```python
# Bad: Fixed chunking without context awareness
def bad_chunking(text, chunk_size=512):
    return [text[i:i+chunk_size] for i in range(0, len(text), chunk_size)]

# Good: Context-aware chunking
def good_chunking(text, chunk_size=512, overlap=50):
    chunks = []
    sentences = text.split('.')
    current_chunk = ""
    
    for sentence in sentences:
        if len(current_chunk + sentence) > chunk_size and current_chunk:
            chunks.append(current_chunk.strip())
            # Keep overlap for context continuity
            words = current_chunk.split()
            current_chunk = ' '.join(words[-overlap:]) + sentence
        else:
            current_chunk += sentence + "."
    
    if current_chunk:
        chunks.append(current_chunk.strip())
    
    return chunks
```

### 2. Embedding Model Selection
```python
# Consider different embedding models for different use cases
embedding_models = {
    'general': 'all-MiniLM-L6-v2',           # Fast, good general performance
    'multilingual': 'paraphrase-multilingual-MiniLM-L12-v2',  # Multiple languages
    'high_quality': 'all-mpnet-base-v2',      # Better quality, slower
    'domain_specific': 'allenai/scibert_scivocab_uncased',  # Scientific texts
    'code': 'microsoft/codebert-base'         # Code understanding
}

def select_embedding_model(domain='general'):
    return embedding_models.get(domain, embedding_models['general'])
```

### 3. Context Window Management
```python
def manage_context_window(documents, query, max_tokens=4000):
    """Intelligently manage context window size"""
    # Estimate tokens (rough approximation)
    def estimate_tokens(text):
        return len(text.split()) * 1.3
    
    query_tokens = estimate_tokens(query)
    available_tokens = max_tokens - query_tokens - 100  # Reserve for response
    
    selected_docs = []
    current_tokens = 0
    
    # Sort documents by relevance score
    documents = sorted(documents, key=lambda x: x.get('score', 0), reverse=True)
    
    for doc in documents:
        doc_tokens = estimate_tokens(doc['content'])
        if current_tokens + doc_tokens <= available_tokens:
            selected_docs.append(doc)
            current_tokens += doc_tokens
        else:
            # Try to include partial content
            remaining_tokens = available_tokens - current_tokens
            if remaining_tokens > 50:  # Minimum viable content
                words = doc['content'].split()
                partial_words = int(remaining_tokens / 1.3)
                partial_content = ' '.join(words[:partial_words])
                selected_docs.append({
                    **doc,
                    'content': partial_content,
                    'truncated': True
                })
            break
    
    return selected_docs
```

## Integration Examples

### ToolFront Integration
```python
# Based on the ToolFront repository structure
import requests
from typing import Dict, Any

class ToolFrontRAGIntegration:
    def __init__(self, toolfront_api_url: str, api_key: str):
        self.api_url = toolfront_api_url
        self.api_key = api_key
        self.headers = {'Authorization': f'Bearer {api_key}'}
    
    def create_rag_tool(self, name: str, description: str, rag_system):
        """Create a ToolFront tool powered by RAG"""
        
        def rag_tool_function(query: str, **kwargs) -> Dict[str, Any]:
            """RAG-powered tool function"""
            try:
                # Query the RAG system
                result = rag_system.query(query)
                
                return {
                    'success': True,
                    'answer': result['answer'],
                    'sources': [
                        {
                            'content': source['content'][:200],
                            'score': source.get('score', 0)
                        }
                        for source in result.get('sources', [])
                    ],
                    'metadata': {
                        'response_time': result.get('response_time', 0),
                        'source_count': len(result.get('sources', []))
                    }
                }
            except Exception as e:
                return {
                    'success': False,
                    'error': str(e)
                }
        
        # Register the tool with ToolFront
        tool_config = {
            'name': name,
            'description': description,
            'function': rag_tool_function,
            'parameters': {
                'query': {
                    'type': 'string',
                    'description': 'The question or query to search for',
                    'required': True
                }
            }
        }
        
        # Register with ToolFront API
        response = requests.post(
            f"{self.api_url}/tools",
            json=tool_config,
            headers=self.headers
        )
        
        return response.json()
    
    def update_knowledge_base(self, documents: list):
        """Update the knowledge base via ToolFront"""
        payload = {
            'action': 'update_knowledge_base',
            'documents': documents
        }
        
        response = requests.post(
            f"{self.api_url}/knowledge_base/update",
            json=payload,
            headers=self.headers
        )
        
        return response.json()

# Usage example
toolfront_integration = ToolFrontRAGIntegration(
    toolfront_api_url="https://api.toolfront.example.com",
    api_key="your-api-key"
)

# Create a RAG-powered tool
tool_response = toolfront_integration.create_rag_tool(
    name="DocumentSearchTool",
    description="Search through company documentation using RAG",
    rag_system=your_rag_system
)
```

This comprehensive RAG best practices guide covers everything from basic implementation to production deployment, including integration with popular tools like ToolFront. The document provides practical examples, optimization strategies, and common pitfalls to help you build robust RAG systems.