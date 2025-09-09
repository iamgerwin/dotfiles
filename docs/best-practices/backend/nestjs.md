# NestJS Best Practices

## Official Documentation
- **NestJS Documentation**: https://docs.nestjs.com
- **NestJS CLI**: https://docs.nestjs.com/cli/overview
- **NestJS Samples**: https://github.com/nestjs/nest/tree/master/sample
- **NestJS DevTools**: https://devtools.nestjs.com

## Project Structure

```
project-root/
├── src/
│   ├── common/
│   │   ├── decorators/        # Custom decorators
│   │   ├── filters/           # Exception filters
│   │   ├── guards/            # Guards (auth, roles)
│   │   ├── interceptors/      # Interceptors
│   │   ├── middleware/        # Middleware
│   │   ├── pipes/             # Validation pipes
│   │   └── interfaces/        # Shared interfaces
│   ├── config/
│   │   ├── configuration.ts   # Configuration loader
│   │   └── validation.ts      # Environment validation
│   ├── modules/
│   │   ├── auth/
│   │   │   ├── dto/          # Data Transfer Objects
│   │   │   ├── entities/     # Database entities
│   │   │   ├── guards/       # Auth-specific guards
│   │   │   ├── strategies/   # Passport strategies
│   │   │   ├── auth.controller.ts
│   │   │   ├── auth.service.ts
│   │   │   ├── auth.module.ts
│   │   │   └── auth.controller.spec.ts
│   │   ├── users/
│   │   │   ├── dto/
│   │   │   ├── entities/
│   │   │   ├── repositories/
│   │   │   ├── users.controller.ts
│   │   │   ├── users.service.ts
│   │   │   └── users.module.ts
│   │   └── shared/
│   │       └── shared.module.ts
│   ├── database/
│   │   ├── migrations/       # Database migrations
│   │   ├── seeds/            # Database seeds
│   │   └── database.module.ts
│   ├── app.module.ts         # Root module
│   ├── app.controller.ts     # Root controller
│   ├── app.service.ts        # Root service
│   └── main.ts               # Application entry point
├── test/
│   ├── e2e/                  # End-to-end tests
│   └── unit/                 # Unit tests
├── dist/                     # Compiled output
├── node_modules/
├── .env                      # Environment variables
├── .env.example
├── .eslintrc.js             # ESLint configuration
├── .prettierrc              # Prettier configuration
├── nest-cli.json            # NestJS CLI configuration
├── ormconfig.ts             # TypeORM configuration
├── package.json
├── tsconfig.json            # TypeScript configuration
└── tsconfig.build.json
```

## Coding Standards

### TypeScript Standards
```typescript
// Use strict TypeScript configuration
{
  "compilerOptions": {
    "strict": true,
    "strictNullChecks": true,
    "strictFunctionTypes": true,
    "strictBindCallApply": true,
    "strictPropertyInitialization": true,
    "noImplicitThis": true,
    "noImplicitAny": true,
    "esModuleInterop": true,
    "skipLibCheck": true
  }
}
```

### Naming Conventions
```typescript
// Controllers - PascalCase with Controller suffix
export class UsersController

// Services - PascalCase with Service suffix
export class UsersService

// Modules - PascalCase with Module suffix
export class UsersModule

// DTOs - PascalCase with Dto suffix
export class CreateUserDto

// Entities - PascalCase, singular
export class User

// Interfaces - PascalCase with I prefix (optional)
export interface IUser

// Enums - PascalCase for name, UPPER_SNAKE_CASE for values
export enum UserRole {
  ADMIN = 'ADMIN',
  USER = 'USER',
}

// Methods - camelCase
getUserById(id: string): Promise<User>

// Private properties - underscore prefix
private readonly _usersRepository: Repository<User>
```

## Best Practices

### 1. Controllers
```typescript
import {
  Controller,
  Get,
  Post,
  Body,
  Param,
  Delete,
  Put,
  UseGuards,
  UseInterceptors,
  HttpCode,
  HttpStatus,
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth } from '@nestjs/swagger';
import { UsersService } from './users.service';
import { CreateUserDto } from './dto/create-user.dto';
import { UpdateUserDto } from './dto/update-user.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { Roles } from '../auth/decorators/roles.decorator';
import { CurrentUser } from '../auth/decorators/current-user.decorator';

@ApiTags('users')
@ApiBearerAuth()
@Controller('users')
@UseGuards(JwtAuthGuard, RolesGuard)
export class UsersController {
  constructor(private readonly usersService: UsersService) {}

  @Post()
  @Roles('admin')
  @ApiOperation({ summary: 'Create a new user' })
  async create(@Body() createUserDto: CreateUserDto) {
    return this.usersService.create(createUserDto);
  }

  @Get()
  @ApiOperation({ summary: 'Get all users' })
  async findAll() {
    return this.usersService.findAll();
  }

  @Get(':id')
  @ApiOperation({ summary: 'Get user by id' })
  async findOne(@Param('id') id: string) {
    return this.usersService.findOne(id);
  }

  @Put(':id')
  @ApiOperation({ summary: 'Update user' })
  async update(
    @Param('id') id: string,
    @Body() updateUserDto: UpdateUserDto,
    @CurrentUser() user: User,
  ) {
    return this.usersService.update(id, updateUserDto, user);
  }

  @Delete(':id')
  @Roles('admin')
  @HttpCode(HttpStatus.NO_CONTENT)
  @ApiOperation({ summary: 'Delete user' })
  async remove(@Param('id') id: string) {
    return this.usersService.remove(id);
  }
}
```

### 2. Services
```typescript
import { Injectable, NotFoundException, ConflictException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { User } from './entities/user.entity';
import { CreateUserDto } from './dto/create-user.dto';
import { UpdateUserDto } from './dto/update-user.dto';
import * as bcrypt from 'bcrypt';

@Injectable()
export class UsersService {
  constructor(
    @InjectRepository(User)
    private readonly usersRepository: Repository<User>,
  ) {}

  async create(createUserDto: CreateUserDto): Promise<User> {
    const existingUser = await this.usersRepository.findOne({
      where: { email: createUserDto.email },
    });

    if (existingUser) {
      throw new ConflictException('User with this email already exists');
    }

    const hashedPassword = await bcrypt.hash(createUserDto.password, 10);
    
    const user = this.usersRepository.create({
      ...createUserDto,
      password: hashedPassword,
    });

    return this.usersRepository.save(user);
  }

  async findAll(): Promise<User[]> {
    return this.usersRepository.find({
      relations: ['profile', 'posts'],
    });
  }

  async findOne(id: string): Promise<User> {
    const user = await this.usersRepository.findOne({
      where: { id },
      relations: ['profile'],
    });

    if (!user) {
      throw new NotFoundException(`User with ID ${id} not found`);
    }

    return user;
  }

  async update(
    id: string,
    updateUserDto: UpdateUserDto,
    currentUser: User,
  ): Promise<User> {
    const user = await this.findOne(id);

    if (updateUserDto.password) {
      updateUserDto.password = await bcrypt.hash(updateUserDto.password, 10);
    }

    Object.assign(user, updateUserDto);
    
    return this.usersRepository.save(user);
  }

  async remove(id: string): Promise<void> {
    const result = await this.usersRepository.delete(id);
    
    if (result.affected === 0) {
      throw new NotFoundException(`User with ID ${id} not found`);
    }
  }
}
```

### 3. DTOs (Data Transfer Objects)
```typescript
import {
  IsEmail,
  IsString,
  IsNotEmpty,
  MinLength,
  IsOptional,
  IsEnum,
  IsUUID,
} from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Transform } from 'class-transformer';
import { UserRole } from '../enums/user-role.enum';

export class CreateUserDto {
  @ApiProperty({ example: 'john.doe@example.com' })
  @IsEmail()
  @IsNotEmpty()
  @Transform(({ value }) => value.toLowerCase())
  email: string;

  @ApiProperty({ example: 'John Doe' })
  @IsString()
  @IsNotEmpty()
  name: string;

  @ApiProperty({ example: 'SecurePassword123!' })
  @IsString()
  @MinLength(8)
  password: string;

  @ApiPropertyOptional({ enum: UserRole })
  @IsEnum(UserRole)
  @IsOptional()
  role?: UserRole = UserRole.USER;
}

export class UpdateUserDto {
  @ApiPropertyOptional()
  @IsEmail()
  @IsOptional()
  @Transform(({ value }) => value?.toLowerCase())
  email?: string;

  @ApiPropertyOptional()
  @IsString()
  @IsOptional()
  name?: string;

  @ApiPropertyOptional()
  @IsString()
  @MinLength(8)
  @IsOptional()
  password?: string;
}
```

### 4. Entities (TypeORM)
```typescript
import {
  Entity,
  Column,
  PrimaryGeneratedColumn,
  CreateDateColumn,
  UpdateDateColumn,
  OneToMany,
  BeforeInsert,
  BeforeUpdate,
} from 'typeorm';
import { Exclude } from 'class-transformer';
import { ApiHideProperty } from '@nestjs/swagger';
import { Post } from '../posts/entities/post.entity';

@Entity('users')
export class User {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ unique: true })
  email: string;

  @Column()
  name: string;

  @Column()
  @Exclude()
  @ApiHideProperty()
  password: string;

  @Column({
    type: 'enum',
    enum: UserRole,
    default: UserRole.USER,
  })
  role: UserRole;

  @Column({ default: true })
  isActive: boolean;

  @OneToMany(() => Post, (post) => post.user)
  posts: Post[];

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;

  @BeforeInsert()
  @BeforeUpdate()
  emailToLowerCase() {
    this.email = this.email.toLowerCase();
  }
}
```

### 5. Modules
```typescript
import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { UsersController } from './users.controller';
import { UsersService } from './users.service';
import { User } from './entities/user.entity';
import { UsersRepository } from './repositories/users.repository';

@Module({
  imports: [TypeOrmModule.forFeature([User])],
  controllers: [UsersController],
  providers: [UsersService, UsersRepository],
  exports: [UsersService], // Export for use in other modules
})
export class UsersModule {}
```

### 6. Configuration
```typescript
// config/configuration.ts
export default () => ({
  port: parseInt(process.env.PORT, 10) || 3000,
  database: {
    host: process.env.DATABASE_HOST,
    port: parseInt(process.env.DATABASE_PORT, 10) || 5432,
    username: process.env.DATABASE_USERNAME,
    password: process.env.DATABASE_PASSWORD,
    database: process.env.DATABASE_NAME,
  },
  jwt: {
    secret: process.env.JWT_SECRET,
    expiresIn: process.env.JWT_EXPIRES_IN || '1d',
  },
  redis: {
    host: process.env.REDIS_HOST,
    port: parseInt(process.env.REDIS_PORT, 10) || 6379,
  },
});

// config/validation.ts
import * as Joi from 'joi';

export const validationSchema = Joi.object({
  NODE_ENV: Joi.string()
    .valid('development', 'production', 'test')
    .default('development'),
  PORT: Joi.number().default(3000),
  DATABASE_HOST: Joi.string().required(),
  DATABASE_PORT: Joi.number().default(5432),
  DATABASE_USERNAME: Joi.string().required(),
  DATABASE_PASSWORD: Joi.string().required(),
  DATABASE_NAME: Joi.string().required(),
  JWT_SECRET: Joi.string().required(),
});
```

### 7. Exception Filters
```typescript
import {
  ExceptionFilter,
  Catch,
  ArgumentsHost,
  HttpException,
  HttpStatus,
  Logger,
} from '@nestjs/common';
import { Request, Response } from 'express';

@Catch()
export class AllExceptionsFilter implements ExceptionFilter {
  private readonly logger = new Logger(AllExceptionsFilter.name);

  catch(exception: unknown, host: ArgumentsHost) {
    const ctx = host.switchToHttp();
    const response = ctx.getResponse<Response>();
    const request = ctx.getRequest<Request>();

    const status =
      exception instanceof HttpException
        ? exception.getStatus()
        : HttpStatus.INTERNAL_SERVER_ERROR;

    const message =
      exception instanceof HttpException
        ? exception.getResponse()
        : 'Internal server error';

    this.logger.error(
      `HTTP ${status} Error: ${JSON.stringify(message)}`,
      exception instanceof Error ? exception.stack : '',
    );

    response.status(status).json({
      statusCode: status,
      timestamp: new Date().toISOString(),
      path: request.url,
      message,
    });
  }
}
```

## Testing

### Unit Tests
```typescript
import { Test, TestingModule } from '@nestjs/testing';
import { UsersService } from './users.service';
import { getRepositoryToken } from '@nestjs/typeorm';
import { User } from './entities/user.entity';
import { Repository } from 'typeorm';

describe('UsersService', () => {
  let service: UsersService;
  let repository: Repository<User>;

  const mockRepository = {
    create: jest.fn(),
    save: jest.fn(),
    find: jest.fn(),
    findOne: jest.fn(),
    delete: jest.fn(),
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        UsersService,
        {
          provide: getRepositoryToken(User),
          useValue: mockRepository,
        },
      ],
    }).compile();

    service = module.get<UsersService>(UsersService);
    repository = module.get<Repository<User>>(getRepositoryToken(User));
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });

  describe('create', () => {
    it('should create a new user', async () => {
      const createUserDto = {
        email: 'test@example.com',
        name: 'Test User',
        password: 'password123',
      };

      const user = { id: '1', ...createUserDto };
      
      mockRepository.findOne.mockResolvedValue(null);
      mockRepository.create.mockReturnValue(user);
      mockRepository.save.mockResolvedValue(user);

      const result = await service.create(createUserDto);
      
      expect(result).toEqual(user);
      expect(mockRepository.save).toHaveBeenCalledWith(user);
    });
  });
});
```

### E2E Tests
```typescript
import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication } from '@nestjs/common';
import * as request from 'supertest';
import { AppModule } from '../src/app.module';

describe('UsersController (e2e)', () => {
  let app: INestApplication;

  beforeEach(async () => {
    const moduleFixture: TestingModule = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();

    app = moduleFixture.createNestApplication();
    await app.init();
  });

  afterEach(async () => {
    await app.close();
  });

  it('/users (GET)', () => {
    return request(app.getHttpServer())
      .get('/users')
      .expect(200)
      .expect((res) => {
        expect(res.body).toBeInstanceOf(Array);
      });
  });

  it('/users (POST)', () => {
    return request(app.getHttpServer())
      .post('/users')
      .send({
        email: 'test@example.com',
        name: 'Test User',
        password: 'password123',
      })
      .expect(201)
      .expect((res) => {
        expect(res.body).toHaveProperty('id');
        expect(res.body.email).toBe('test@example.com');
      });
  });
});
```

## Security Best Practices

### Authentication (JWT)
```typescript
// auth/strategies/jwt.strategy.ts
import { ExtractJwt, Strategy } from 'passport-jwt';
import { PassportStrategy } from '@nestjs/passport';
import { Injectable, UnauthorizedException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

@Injectable()
export class JwtStrategy extends PassportStrategy(Strategy) {
  constructor(
    private configService: ConfigService,
    private usersService: UsersService,
  ) {
    super({
      jwtFromRequest: ExtractJwt.fromAuthHeaderAsBearerToken(),
      ignoreExpiration: false,
      secretOrKey: configService.get('jwt.secret'),
    });
  }

  async validate(payload: any) {
    const user = await this.usersService.findOne(payload.sub);
    if (!user) {
      throw new UnauthorizedException();
    }
    return user;
  }
}
```

### Rate Limiting
```typescript
// main.ts
import { rateLimit } from 'express-rate-limit';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);
  
  app.use(
    rateLimit({
      windowMs: 15 * 60 * 1000, // 15 minutes
      max: 100, // limit each IP to 100 requests per windowMs
    }),
  );
  
  await app.listen(3000);
}
```

### Validation
```typescript
// main.ts
app.useGlobalPipes(
  new ValidationPipe({
    whitelist: true, // Strip properties that don't have decorators
    forbidNonWhitelisted: true, // Throw error for non-whitelisted properties
    transform: true, // Automatically transform payloads
    transformOptions: {
      enableImplicitConversion: true,
    },
  }),
);
```

## Performance Optimization

### Caching
```typescript
import { CacheModule, CacheInterceptor } from '@nestjs/cache-manager';
import * as redisStore from 'cache-manager-redis-store';

@Module({
  imports: [
    CacheModule.register({
      store: redisStore,
      host: 'localhost',
      port: 6379,
      ttl: 60, // seconds
    }),
  ],
})
export class AppModule {}

// Use in controller
@UseInterceptors(CacheInterceptor)
@Get()
async findAll() {
  return this.usersService.findAll();
}
```

### Database Query Optimization
```typescript
// Use query builder for complex queries
const users = await this.usersRepository
  .createQueryBuilder('user')
  .leftJoinAndSelect('user.posts', 'post')
  .where('user.isActive = :isActive', { isActive: true })
  .orderBy('user.createdAt', 'DESC')
  .limit(10)
  .getMany();

// Use pagination
async findAll(page: number = 1, limit: number = 10) {
  const [data, total] = await this.usersRepository.findAndCount({
    skip: (page - 1) * limit,
    take: limit,
  });
  
  return {
    data,
    total,
    page,
    lastPage: Math.ceil(total / limit),
  };
}
```

## Common CLI Commands

```bash
# Installation
npm i -g @nestjs/cli

# Create new project
nest new project-name

# Generate resources
nest g module users
nest g controller users
nest g service users
nest g resource users # Creates module, controller, service, DTOs

# Run application
npm run start           # Standard mode
npm run start:dev      # Watch mode
npm run start:debug    # Debug mode
npm run start:prod     # Production mode

# Testing
npm run test           # Unit tests
npm run test:watch     # Watch mode
npm run test:cov       # Coverage
npm run test:e2e       # E2E tests

# Build
npm run build          # Build application

# Database
npm run migration:generate -- -n MigrationName
npm run migration:run
npm run migration:revert
```

## Recommended Packages

- **@nestjs/config**: Configuration management
- **@nestjs/jwt**: JWT authentication
- **@nestjs/passport**: Authentication
- **@nestjs/swagger**: API documentation
- **@nestjs/typeorm**: TypeORM integration
- **@nestjs/mongoose**: MongoDB integration
- **@nestjs/graphql**: GraphQL support
- **@nestjs/microservices**: Microservices
- **@nestjs/websockets**: WebSocket support
- **@nestjs/cache-manager**: Caching
- **@nestjs/throttler**: Rate limiting
- **class-validator**: DTO validation
- **class-transformer**: DTO transformation

## Resources
- **NestJS Awesome**: https://github.com/nestjs/awesome-nestjs
- **NestJS Recipes**: https://github.com/nestjs/nest/tree/master/sample
- **Enterprise Architecture**: https://github.com/nestjs/nest/tree/master/sample/32-graphql-federation-code-first