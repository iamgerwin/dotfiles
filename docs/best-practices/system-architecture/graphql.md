# GraphQL Best Practices

## Official Documentation
- **GraphQL Specification**: https://spec.graphql.org
- **GraphQL.org**: https://graphql.org
- **GraphQL Foundation**: https://foundation.graphql.org
- **Apollo GraphQL**: https://www.apollographql.com/docs

## Schema Design

### Schema Definition Language (SDL)
```graphql
# Use descriptive names and proper casing
type User {
  id: ID!
  email: String!
  firstName: String!
  lastName: String!
  fullName: String! # Computed field
  posts: [Post!]!
  createdAt: DateTime!
  updatedAt: DateTime!
}

type Post {
  id: ID!
  title: String!
  content: String!
  published: Boolean!
  author: User!
  tags: [Tag!]!
  createdAt: DateTime!
  updatedAt: DateTime!
}

type Tag {
  id: ID!
  name: String!
  posts: [Post!]!
}

# Custom scalar types
scalar DateTime
scalar Email
scalar URL
```

### Input Types and Validation
```graphql
# Use input types for mutations
input CreateUserInput {
  email: Email!
  firstName: String!
  lastName: String!
  password: String!
}

input UpdateUserInput {
  firstName: String
  lastName: String
  email: Email
}

input PostFilters {
  authorId: ID
  published: Boolean
  tags: [String!]
  searchTerm: String
  dateRange: DateRangeInput
}

input DateRangeInput {
  startDate: DateTime!
  endDate: DateTime!
}

# Use enums for fixed sets of values
enum PostStatus {
  DRAFT
  PUBLISHED
  ARCHIVED
}

enum SortOrder {
  ASC
  DESC
}
```

### Pagination and Connections
```graphql
# Implement Relay-style cursor-based pagination
type Query {
  posts(
    first: Int
    after: String
    last: Int
    before: String
    filters: PostFilters
  ): PostConnection!
}

type PostConnection {
  edges: [PostEdge!]!
  pageInfo: PageInfo!
  totalCount: Int!
}

type PostEdge {
  node: Post!
  cursor: String!
}

type PageInfo {
  hasNextPage: Boolean!
  hasPreviousPage: Boolean!
  startCursor: String
  endCursor: String
}
```

## Resolver Implementation

### Node.js with Apollo Server
```javascript
const { ApolloServer } = require('apollo-server-express');
const { GraphQLScalarType } = require('graphql');
const { Kind } = require('graphql/language');
const DataLoader = require('dataloader');

// Custom scalar types
const DateTimeType = new GraphQLScalarType({
  name: 'DateTime',
  serialize: (value) => value.toISOString(),
  parseValue: (value) => new Date(value),
  parseLiteral: (ast) => {
    if (ast.kind === Kind.STRING) {
      return new Date(ast.value);
    }
    return null;
  },
});

// DataLoader for N+1 problem prevention
const createUserLoader = (userService) => {
  return new DataLoader(async (userIds) => {
    const users = await userService.findByIds(userIds);
    const userMap = new Map(users.map(user => [user.id, user]));
    return userIds.map(id => userMap.get(id));
  });
};

const resolvers = {
  DateTime: DateTimeType,
  
  Query: {
    user: async (parent, { id }, context) => {
      return await context.dataSources.userAPI.findById(id);
    },
    
    posts: async (parent, args, context) => {
      const { first, after, filters } = args;
      return await context.dataSources.postAPI.findMany({
        limit: first,
        cursor: after,
        filters
      });
    }
  },
  
  Mutation: {
    createUser: async (parent, { input }, context) => {
      // Validate permissions
      if (!context.user || !context.user.canCreateUsers) {
        throw new ForbiddenError('Insufficient permissions');
      }
      
      // Validate input
      const { error, value } = userSchema.validate(input);
      if (error) {
        throw new UserInputError('Invalid input', { validationErrors: error.details });
      }
      
      try {
        const user = await context.dataSources.userAPI.create(value);
        
        // Publish subscription event
        context.pubsub.publish('USER_CREATED', { userCreated: user });
        
        return {
          success: true,
          user,
          errors: []
        };
      } catch (error) {
        return {
          success: false,
          user: null,
          errors: [{
            field: 'email',
            message: 'Email already exists'
          }]
        };
      }
    }
  },
  
  User: {
    fullName: (parent) => `${parent.firstName} ${parent.lastName}`,
    
    posts: async (parent, args, context) => {
      return await context.dataSources.postAPI.findByAuthorId(parent.id, args);
    }
  },
  
  Post: {
    author: async (parent, args, context) => {
      return await context.loaders.user.load(parent.authorId);
    },
    
    tags: async (parent, args, context) => {
      return await context.dataSources.tagAPI.findByPostId(parent.id);
    }
  },
  
  Subscription: {
    userCreated: {
      subscribe: (parent, args, context) => {
        return context.pubsub.asyncIterator(['USER_CREATED']);
      }
    }
  }
};

// Apollo Server configuration
const server = new ApolloServer({
  typeDefs,
  resolvers,
  context: ({ req, connection }) => {
    if (connection) {
      return connection.context;
    }
    
    return {
      user: req.user,
      dataSources: {
        userAPI: new UserAPI(),
        postAPI: new PostAPI(),
        tagAPI: new TagAPI()
      },
      loaders: {
        user: createUserLoader(userService),
        post: createPostLoader(postService)
      },
      pubsub: new PubSub()
    };
  },
  plugins: [
    // Query complexity analysis
    require('graphql-query-complexity').createComplexityLimitRule(1000),
    // Query depth limiting
    require('graphql-depth-limit')(10)
  ],
  formatError: (error) => {
    console.error(error);
    
    // Don't expose internal errors to clients
    if (error.message.startsWith('Database')) {
      return new Error('Internal server error');
    }
    
    return error;
  }
});
```

### Python with Strawberry
```python
import strawberry
from typing import List, Optional
from dataclasses import dataclass
from datetime import datetime

@strawberry.type
class User:
    id: strawberry.ID
    email: str
    first_name: str
    last_name: str
    created_at: datetime
    
    @strawberry.field
    def full_name(self) -> str:
        return f"{self.first_name} {self.last_name}"
    
    @strawberry.field
    async def posts(self, info) -> List['Post']:
        return await info.context.post_service.get_by_author_id(self.id)

@strawberry.type
class Post:
    id: strawberry.ID
    title: str
    content: str
    published: bool
    created_at: datetime
    
    @strawberry.field
    async def author(self, info) -> User:
        return await info.context.user_loader.load(self.author_id)

@strawberry.input
class CreateUserInput:
    email: str
    first_name: str
    last_name: str
    password: str

@strawberry.input
class PostFilters:
    author_id: Optional[strawberry.ID] = None
    published: Optional[bool] = None
    search_term: Optional[str] = None

@strawberry.type
class CreateUserPayload:
    success: bool
    user: Optional[User]
    errors: List[str]

@strawberry.type
class Query:
    @strawberry.field
    async def user(self, info, id: strawberry.ID) -> Optional[User]:
        return await info.context.user_service.get_by_id(id)
    
    @strawberry.field
    async def posts(
        self, 
        info,
        first: Optional[int] = None,
        after: Optional[str] = None,
        filters: Optional[PostFilters] = None
    ) -> PostConnection:
        return await info.context.post_service.get_connection(
            first=first, after=after, filters=filters
        )

@strawberry.type
class Mutation:
    @strawberry.field
    async def create_user(
        self, 
        info, 
        input: CreateUserInput
    ) -> CreateUserPayload:
        try:
            # Validate permissions
            if not info.context.user or not info.context.user.can_create_users:
                return CreateUserPayload(
                    success=False, 
                    user=None, 
                    errors=["Insufficient permissions"]
                )
            
            user = await info.context.user_service.create(input)
            return CreateUserPayload(success=True, user=user, errors=[])
            
        except ValidationError as e:
            return CreateUserPayload(
                success=False, 
                user=None, 
                errors=e.messages
            )

schema = strawberry.Schema(query=Query, mutation=Mutation)
```

## Security Best Practices

### Authentication and Authorization
```javascript
// JWT-based authentication
const jwt = require('jsonwebtoken');

const authContext = async (req) => {
  const token = req.headers.authorization?.replace('Bearer ', '');
  
  if (!token) {
    return { user: null };
  }
  
  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    const user = await User.findById(decoded.userId);
    return { user };
  } catch (error) {
    return { user: null };
  }
};

// Field-level authorization
const resolvers = {
  User: {
    email: (parent, args, context) => {
      // Only return email for the current user or admins
      if (context.user?.id === parent.id || context.user?.role === 'admin') {
        return parent.email;
      }
      throw new ForbiddenError('Cannot access email');
    }
  }
};

// Directive-based authorization
const { SchemaDirectiveVisitor } = require('apollo-server-express');

class AuthDirective extends SchemaDirectiveVisitor {
  visitFieldDefinition(field) {
    const { resolve = defaultFieldResolver } = field;
    const requiredRole = this.args.requires;
    
    field.resolve = async function (parent, args, context, info) {
      if (!context.user) {
        throw new AuthenticationError('You must be signed in');
      }
      
      if (requiredRole && context.user.role !== requiredRole) {
        throw new ForbiddenError('Insufficient role');
      }
      
      return resolve.call(this, parent, args, context, info);
    };
  }
}

// Schema with directives
const typeDefs = `
  directive @auth(requires: Role = USER) on FIELD_DEFINITION
  
  enum Role {
    ADMIN
    USER
  }
  
  type User {
    id: ID!
    email: String! @auth
    adminNotes: String @auth(requires: ADMIN)
  }
`;
```

### Input Validation and Sanitization
```javascript
const Joi = require('joi');
const { UserInputError } = require('apollo-server-express');

// Define validation schemas
const schemas = {
  createUser: Joi.object({
    email: Joi.string().email().required(),
    firstName: Joi.string().min(2).max(50).required(),
    lastName: Joi.string().min(2).max(50).required(),
    password: Joi.string().min(8).pattern(/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)/).required()
  }),
  
  updatePost: Joi.object({
    title: Joi.string().min(5).max(200),
    content: Joi.string().min(10).max(10000),
    published: Joi.boolean()
  })
};

// Validation middleware
const validateInput = (schema) => (parent, args, context, info) => {
  const { error, value } = schema.validate(args.input);
  
  if (error) {
    throw new UserInputError('Validation failed', {
      validationErrors: error.details.map(detail => ({
        field: detail.path.join('.'),
        message: detail.message
      }))
    });
  }
  
  // Replace args.input with validated/sanitized value
  args.input = value;
};

// Apply validation to resolvers
const resolvers = {
  Mutation: {
    createUser: validateInput(schemas.createUser)(async (parent, args, context) => {
      // Implementation here
    })
  }
};
```

### Rate Limiting and Query Complexity
```javascript
const { shield, rule, and, or, not } = require('graphql-shield');
const { RateLimiterMemory } = require('rate-limiter-flexible');

// Rate limiter
const rateLimiter = new RateLimiterMemory({
  points: 100, // Number of requests
  duration: 60, // Per 60 seconds
});

const rateLimit = rule({ cache: 'contextual' })(
  async (parent, args, context, info) => {
    const key = context.user?.id || context.req.ip;
    
    try {
      await rateLimiter.consume(key);
      return true;
    } catch {
      return new Error('Rate limit exceeded');
    }
  }
);

// Query complexity analysis
const depthLimit = require('graphql-depth-limit');
const costAnalysis = require('graphql-cost-analysis');

const server = new ApolloServer({
  typeDefs,
  resolvers,
  validationRules: [
    depthLimit(10),
    costAnalysis({
      maximumCost: 1000,
      createError: (max, actual) => 
        new Error(`Query cost ${actual} exceeds maximum cost ${max}`)
    })
  ],
  plugins: [
    {
      requestDidStart() {
        return {
          didResolveOperation({ request, document }) {
            const complexity = getComplexity({
              schema,
              query: document,
              variables: request.variables,
              createError: (max, actual) =>
                new Error(`Query complexity ${actual} exceeds maximum ${max}`)
            });
          }
        };
      }
    }
  ]
});
```

## Performance Optimization

### DataLoader for N+1 Problem
```javascript
const DataLoader = require('dataloader');

class DataLoaders {
  constructor({ userService, postService, tagService }) {
    this.user = new DataLoader(
      async (userIds) => {
        const users = await userService.findByIds(userIds);
        const userMap = new Map(users.map(user => [user.id, user]));
        return userIds.map(id => userMap.get(id) || null);
      },
      {
        // Cache for the duration of a single request
        cacheKeyFn: (key) => key,
        batchScheduleFn: (callback) => setTimeout(callback, 10)
      }
    );
    
    this.postsByAuthor = new DataLoader(
      async (authorIds) => {
        const posts = await postService.findByAuthorIds(authorIds);
        const postMap = new Map();
        
        posts.forEach(post => {
          if (!postMap.has(post.authorId)) {
            postMap.set(post.authorId, []);
          }
          postMap.get(post.authorId).push(post);
        });
        
        return authorIds.map(id => postMap.get(id) || []);
      }
    );
  }
}

// Usage in context
const server = new ApolloServer({
  context: ({ req }) => {
    return {
      user: req.user,
      loaders: new DataLoaders({ userService, postService, tagService })
    };
  }
});
```

### Caching Strategies
```javascript
const Redis = require('redis');
const { RedisCache } = require('apollo-server-cache-redis');

// Redis caching
const redis = Redis.createClient();

const server = new ApolloServer({
  typeDefs,
  resolvers,
  cache: new RedisCache({
    host: 'localhost',
    port: 6379,
    db: 0,
  }),
  cacheControl: {
    defaultMaxAge: 300, // 5 minutes
  },
  plugins: [
    require('apollo-cache-control'),
    require('apollo-server-plugin-response-cache')()
  ]
});

// Field-level caching
const resolvers = {
  Query: {
    posts: async (parent, args, context, info) => {
      // Cache key based on arguments
      const cacheKey = `posts:${JSON.stringify(args)}`;
      
      // Try to get from cache
      const cached = await context.cache.get(cacheKey);
      if (cached) {
        return JSON.parse(cached);
      }
      
      // Fetch from database
      const posts = await context.dataSources.postAPI.findMany(args);
      
      // Cache for 5 minutes
      await context.cache.set(cacheKey, JSON.stringify(posts), { ttl: 300 });
      
      return posts;
    }
  },
  
  User: {
    posts: (parent, args, context, info) => {
      // Set cache hints
      info.cacheControl.setCacheHint({ maxAge: 60, scope: 'PRIVATE' });
      return context.loaders.postsByAuthor.load(parent.id);
    }
  }
};
```

### Query Optimization
```javascript
// Implement field selection optimization
const { parseResolveInfo } = require('graphql-parse-resolve-info');

const resolvers = {
  Query: {
    users: async (parent, args, context, info) => {
      const parsedInfo = parseResolveInfo(info);
      
      // Only select requested fields
      const fields = Object.keys(parsedInfo.fieldsByTypeName.User);
      const includeRelations = {
        posts: fields.includes('posts'),
        profile: fields.includes('profile')
      };
      
      return await context.dataSources.userAPI.findMany({
        ...args,
        select: fields,
        include: includeRelations
      });
    }
  }
};

// Implement query batching
const { createBatchingExecutor } = require('@graphql-tools/batch-execute');

const executor = createBatchingExecutor({
  executor: (document, variables, context) => 
    execute({ schema, document, variableValues: variables, contextValue: context }),
  batchingOptions: {
    maxBatchSize: 10,
    batchScheduleFn: (callback) => setTimeout(callback, 10)
  }
});
```

## Testing Strategies

### Unit Testing Resolvers
```javascript
const { graphql } = require('graphql');
const { createTestClient } = require('apollo-server-testing');
const { ApolloServer } = require('apollo-server');

describe('GraphQL Resolvers', () => {
  let server;
  let testClient;
  
  beforeEach(() => {
    const mockDataSources = {
      userAPI: {
        findById: jest.fn(),
        create: jest.fn()
      }
    };
    
    server = new ApolloServer({
      typeDefs,
      resolvers,
      dataSources: () => mockDataSources,
      context: () => ({
        user: { id: '1', role: 'admin' }
      })
    });
    
    testClient = createTestClient(server);
  });
  
  it('should create a user', async () => {
    const CREATE_USER = `
      mutation CreateUser($input: CreateUserInput!) {
        createUser(input: $input) {
          success
          user {
            id
            email
            fullName
          }
          errors
        }
      }
    `;
    
    const mockUser = {
      id: '1',
      email: 'test@example.com',
      firstName: 'John',
      lastName: 'Doe'
    };
    
    server.dataSources().userAPI.create.mockResolvedValue(mockUser);
    
    const { data } = await testClient.mutate({
      mutation: CREATE_USER,
      variables: {
        input: {
          email: 'test@example.com',
          firstName: 'John',
          lastName: 'Doe',
          password: 'SecurePass123'
        }
      }
    });
    
    expect(data.createUser.success).toBe(true);
    expect(data.createUser.user.fullName).toBe('John Doe');
    expect(server.dataSources().userAPI.create).toHaveBeenCalledWith({
      email: 'test@example.com',
      firstName: 'John',
      lastName: 'Doe',
      password: 'SecurePass123'
    });
  });
});
```

### Integration Testing
```javascript
const request = require('supertest');
const app = require('../app');

describe('GraphQL Integration Tests', () => {
  beforeEach(async () => {
    await setupDatabase();
  });
  
  afterEach(async () => {
    await cleanupDatabase();
  });
  
  it('should handle complex queries', async () => {
    const query = `
      query GetUsersWithPosts {
        users(first: 10) {
          edges {
            node {
              id
              fullName
              posts(first: 5) {
                edges {
                  node {
                    title
                    published
                  }
                }
              }
            }
          }
          pageInfo {
            hasNextPage
            endCursor
          }
        }
      }
    `;
    
    const response = await request(app)
      .post('/graphql')
      .send({ query })
      .expect(200);
    
    expect(response.body.data.users.edges).toHaveLength(10);
    expect(response.body.data.users.pageInfo.hasNextPage).toBeDefined();
  });
});
```

## Client Integration

### Apollo Client Setup
```javascript
import { ApolloClient, InMemoryCache, createHttpLink, from } from '@apollo/client';
import { setContext } from '@apollo/client/link/context';
import { onError } from '@apollo/client/link/error';

const httpLink = createHttpLink({
  uri: 'http://localhost:4000/graphql',
});

const authLink = setContext((_, { headers }) => {
  const token = localStorage.getItem('token');
  return {
    headers: {
      ...headers,
      authorization: token ? `Bearer ${token}` : "",
    }
  };
});

const errorLink = onError(({ graphQLErrors, networkError, operation, forward }) => {
  if (graphQLErrors) {
    graphQLErrors.forEach(({ message, locations, path }) => {
      console.error(`GraphQL error: Message: ${message}, Location: ${locations}, Path: ${path}`);
    });
  }
  
  if (networkError) {
    console.error(`Network error: ${networkError}`);
    
    if (networkError.statusCode === 401) {
      localStorage.removeItem('token');
      window.location.href = '/login';
    }
  }
});

const client = new ApolloClient({
  link: from([errorLink, authLink, httpLink]),
  cache: new InMemoryCache({
    typePolicies: {
      Post: {
        fields: {
          comments: {
            merge(existing = [], incoming) {
              return [...existing, ...incoming];
            }
          }
        }
      }
    }
  }),
  defaultOptions: {
    watchQuery: {
      errorPolicy: 'all'
    },
    query: {
      errorPolicy: 'all'
    }
  }
});

export default client;
```

### React Hooks Usage
```javascript
import { useQuery, useMutation, useSubscription } from '@apollo/client';
import { gql } from '@apollo/client';

const GET_POSTS = gql`
  query GetPosts($first: Int, $after: String, $filters: PostFilters) {
    posts(first: $first, after: $after, filters: $filters) {
      edges {
        node {
          id
          title
          content
          published
          author {
            fullName
          }
          tags {
            name
          }
        }
        cursor
      }
      pageInfo {
        hasNextPage
        endCursor
      }
    }
  }
`;

const CREATE_POST = gql`
  mutation CreatePost($input: CreatePostInput!) {
    createPost(input: $input) {
      success
      post {
        id
        title
        published
      }
      errors {
        field
        message
      }
    }
  }
`;

const POST_CREATED = gql`
  subscription PostCreated {
    postCreated {
      id
      title
      author {
        fullName
      }
    }
  }
`;

function PostList() {
  const { data, loading, error, fetchMore } = useQuery(GET_POSTS, {
    variables: { first: 10 },
    notifyOnNetworkStatusChange: true
  });
  
  const [createPost] = useMutation(CREATE_POST, {
    update(cache, { data: { createPost } }) {
      if (createPost.success) {
        cache.modify({
          fields: {
            posts(existing = { edges: [] }) {
              const newPostRef = cache.writeFragment({
                data: createPost.post,
                fragment: gql`
                  fragment NewPost on Post {
                    id
                    title
                    published
                  }
                `
              });
              return {
                ...existing,
                edges: [{ node: newPostRef, cursor: 'new' }, ...existing.edges]
              };
            }
          }
        });
      }
    }
  });
  
  useSubscription(POST_CREATED, {
    onSubscriptionData: ({ subscriptionData }) => {
      console.log('New post created:', subscriptionData.data.postCreated);
    }
  });
  
  const handleLoadMore = () => {
    if (data?.posts.pageInfo.hasNextPage) {
      fetchMore({
        variables: {
          after: data.posts.pageInfo.endCursor
        }
      });
    }
  };
  
  if (loading) return <div>Loading...</div>;
  if (error) return <div>Error: {error.message}</div>;
  
  return (
    <div>
      {data.posts.edges.map(({ node: post }) => (
        <div key={post.id}>
          <h3>{post.title}</h3>
          <p>By: {post.author.fullName}</p>
          <div>Tags: {post.tags.map(tag => tag.name).join(', ')}</div>
        </div>
      ))}
      
      {data.posts.pageInfo.hasNextPage && (
        <button onClick={handleLoadMore}>Load More</button>
      )}
    </div>
  );
}
```

## Common Pitfalls

1. **N+1 Problem**: Always use DataLoader for related data
2. **Over-fetching**: Implement proper field selection in resolvers
3. **Under-fetching**: Design schema to minimize round trips
4. **No query complexity analysis**: Implement depth/complexity limits
5. **Weak error handling**: Provide meaningful error messages
6. **No input validation**: Always validate and sanitize inputs
7. **Missing authorization**: Implement field-level security
8. **No caching strategy**: Use appropriate caching mechanisms
9. **Poor schema design**: Follow GraphQL schema design best practices
10. **Ignoring subscriptions cleanup**: Properly handle subscription lifecycles