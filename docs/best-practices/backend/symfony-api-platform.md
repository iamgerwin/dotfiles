# Symfony with API Platform Best Practices

## Official Documentation
- **Symfony Documentation**: https://symfony.com/doc/current/index.html
- **API Platform Documentation**: https://api-platform.com/docs
- **Symfony Best Practices**: https://symfony.com/doc/current/best_practices.html
- **Doctrine ORM**: https://www.doctrine-project.org/projects/orm.html

## Project Structure

```
project-root/
├── assets/
│   ├── controllers/
│   ├── styles/
│   └── app.js
├── bin/
│   └── console
├── config/
│   ├── packages/
│   │   ├── api_platform.yaml
│   │   ├── doctrine.yaml
│   │   ├── security.yaml
│   │   └── validator.yaml
│   ├── routes/
│   │   └── api_platform.yaml
│   ├── bundles.php
│   ├── routes.yaml
│   └── services.yaml
├── migrations/
├── public/
│   └── index.php
├── src/
│   ├── ApiResource/
│   │   ├── User.php
│   │   └── Product.php
│   ├── Command/
│   ├── Controller/
│   │   ├── Api/
│   │   └── Admin/
│   ├── DataFixtures/
│   ├── DataPersister/
│   ├── DataProvider/
│   ├── DataTransformer/
│   ├── Doctrine/
│   │   └── Extension/
│   ├── Entity/
│   │   ├── User.php
│   │   └── Product.php
│   ├── EventSubscriber/
│   ├── Filter/
│   ├── Repository/
│   ├── Security/
│   │   ├── Voter/
│   │   └── Authenticator/
│   ├── Serializer/
│   │   └── Normalizer/
│   ├── Service/
│   ├── State/
│   │   ├── Processor/
│   │   └── Provider/
│   ├── Validator/
│   └── Kernel.php
├── templates/
├── tests/
│   ├── Api/
│   ├── Functional/
│   └── Unit/
├── var/
├── vendor/
├── .env
├── .env.test
├── composer.json
├── docker-compose.yml
├── phpunit.xml.dist
└── symfony.lock
```

## Core Best Practices

### 1. API Resource Configuration (API Platform 3.0+)

```php
<?php

namespace App\ApiResource;

use ApiPlatform\Metadata\ApiResource;
use ApiPlatform\Metadata\ApiProperty;
use ApiPlatform\Metadata\Get;
use ApiPlatform\Metadata\GetCollection;
use ApiPlatform\Metadata\Post;
use ApiPlatform\Metadata\Put;
use ApiPlatform\Metadata\Patch;
use ApiPlatform\Metadata\Delete;
use ApiPlatform\Metadata\ApiFilter;
use ApiPlatform\Doctrine\Orm\Filter\SearchFilter;
use ApiPlatform\Doctrine\Orm\Filter\OrderFilter;
use ApiPlatform\Doctrine\Orm\Filter\DateFilter;
use ApiPlatform\Serializer\Filter\PropertyFilter;
use App\State\UserPasswordHasher;
use App\State\UserProvider;
use Symfony\Component\Serializer\Annotation\Groups;
use Symfony\Component\Validator\Constraints as Assert;

#[ApiResource(
    description: 'User resource',
    operations: [
        new GetCollection(
            uriTemplate: '/users',
            paginationEnabled: true,
            paginationItemsPerPage: 20,
            security: "is_granted('ROLE_ADMIN')"
        ),
        new Get(
            uriTemplate: '/users/{id}',
            requirements: ['id' => '\d+'],
            security: "is_granted('USER_VIEW', object)"
        ),
        new Post(
            uriTemplate: '/users',
            processor: UserPasswordHasher::class,
            validationContext: ['groups' => ['user:create']]
        ),
        new Put(
            uriTemplate: '/users/{id}',
            requirements: ['id' => '\d+'],
            security: "is_granted('USER_EDIT', object)",
            validationContext: ['groups' => ['user:update']]
        ),
        new Patch(
            uriTemplate: '/users/{id}',
            requirements: ['id' => '\d+'],
            security: "is_granted('USER_EDIT', object)",
            inputFormats: ['json' => ['application/merge-patch+json']]
        ),
        new Delete(
            uriTemplate: '/users/{id}',
            requirements: ['id' => '\d+'],
            security: "is_granted('ROLE_ADMIN')"
        )
    ],
    normalizationContext: ['groups' => ['user:read']],
    denormalizationContext: ['groups' => ['user:write']],
    order: ['createdAt' => 'DESC'],
    mercure: true,
    messenger: true,
    elasticsearch: false
)]
#[ApiFilter(SearchFilter::class, properties: [
    'email' => 'partial',
    'firstName' => 'partial',
    'lastName' => 'partial',
    'status' => 'exact'
])]
#[ApiFilter(OrderFilter::class, properties: ['email', 'createdAt', 'lastName'])]
#[ApiFilter(DateFilter::class, properties: ['createdAt'])]
#[ApiFilter(PropertyFilter::class)]
class User
{
    #[ApiProperty(identifier: true)]
    #[Groups(['user:read'])]
    private ?int $id = null;

    #[Assert\NotBlank(groups: ['user:create'])]
    #[Assert\Email(groups: ['user:create', 'user:update'])]
    #[Groups(['user:read', 'user:write'])]
    private ?string $email = null;

    #[Assert\NotBlank(groups: ['user:create'])]
    #[Assert\Length(min: 8, groups: ['user:create'])]
    #[Groups(['user:write'])]
    private ?string $plainPassword = null;

    #[Groups(['user:read'])]
    private array $roles = [];

    #[Assert\NotBlank(groups: ['user:create', 'user:update'])]
    #[Assert\Length(min: 2, max: 50)]
    #[Groups(['user:read', 'user:write'])]
    private ?string $firstName = null;

    #[Assert\NotBlank(groups: ['user:create', 'user:update'])]
    #[Assert\Length(min: 2, max: 50)]
    #[Groups(['user:read', 'user:write'])]
    private ?string $lastName = null;

    #[Groups(['user:read', 'admin:write'])]
    private ?string $status = 'active';

    #[Groups(['user:read'])]
    private ?\DateTimeImmutable $createdAt = null;

    #[Groups(['user:read'])]
    private ?\DateTimeImmutable $updatedAt = null;

    // Getters and setters...
}
```

### 2. Entity with Doctrine ORM

```php
<?php

namespace App\Entity;

use App\Repository\ProductRepository;
use Doctrine\Common\Collections\ArrayCollection;
use Doctrine\Common\Collections\Collection;
use Doctrine\DBAL\Types\Types;
use Doctrine\ORM\Mapping as ORM;
use Gedmo\Mapping\Annotation as Gedmo;
use Symfony\Component\Validator\Constraints as Assert;
use Symfony\Bridge\Doctrine\Validator\Constraints\UniqueEntity;

#[ORM\Entity(repositoryClass: ProductRepository::class)]
#[ORM\Table(name: 'products')]
#[ORM\Index(columns: ['sku'], name: 'idx_product_sku')]
#[ORM\Index(columns: ['status', 'created_at'], name: 'idx_product_status_date')]
#[ORM\HasLifecycleCallbacks]
#[UniqueEntity(fields: ['sku'], message: 'This SKU is already in use')]
#[Gedmo\SoftDeleteable(fieldName: 'deletedAt', timeAware: false)]
class Product
{
    #[ORM\Id]
    #[ORM\GeneratedValue]
    #[ORM\Column(type: Types::INTEGER)]
    private ?int $id = null;

    #[ORM\Column(type: Types::STRING, length: 255)]
    #[Assert\NotBlank]
    #[Assert\Length(min: 3, max: 255)]
    private ?string $name = null;

    #[ORM\Column(type: Types::STRING, length: 100, unique: true)]
    #[Assert\NotBlank]
    #[Assert\Regex(
        pattern: '/^[A-Z0-9\-]+$/',
        message: 'SKU must contain only uppercase letters, numbers, and hyphens'
    )]
    private ?string $sku = null;

    #[ORM\Column(type: Types::TEXT, nullable: true)]
    private ?string $description = null;

    #[ORM\Column(type: Types::DECIMAL, precision: 10, scale: 2)]
    #[Assert\NotBlank]
    #[Assert\PositiveOrZero]
    private ?string $price = null;

    #[ORM\Column(type: Types::INTEGER)]
    #[Assert\NotBlank]
    #[Assert\PositiveOrZero]
    private ?int $stock = 0;

    #[ORM\Column(type: Types::STRING, length: 20)]
    #[Assert\Choice(choices: ['active', 'inactive', 'discontinued'])]
    private string $status = 'active';

    #[ORM\ManyToOne(targetEntity: Category::class, inversedBy: 'products')]
    #[ORM\JoinColumn(nullable: false)]
    private ?Category $category = null;

    #[ORM\ManyToMany(targetEntity: Tag::class, inversedBy: 'products')]
    #[ORM\JoinTable(name: 'product_tags')]
    private Collection $tags;

    #[ORM\OneToMany(mappedBy: 'product', targetEntity: ProductImage::class, cascade: ['persist', 'remove'], orphanRemoval: true)]
    #[ORM\OrderBy(['position' => 'ASC'])]
    private Collection $images;

    #[ORM\Column(type: Types::DATETIME_IMMUTABLE)]
    #[Gedmo\Timestampable(on: 'create')]
    private ?\DateTimeImmutable $createdAt = null;

    #[ORM\Column(type: Types::DATETIME_IMMUTABLE)]
    #[Gedmo\Timestampable(on: 'update')]
    private ?\DateTimeImmutable $updatedAt = null;

    #[ORM\Column(type: Types::DATETIME_IMMUTABLE, nullable: true)]
    private ?\DateTimeImmutable $deletedAt = null;

    #[ORM\Version]
    #[ORM\Column(type: Types::INTEGER)]
    private ?int $version = 1;

    public function __construct()
    {
        $this->tags = new ArrayCollection();
        $this->images = new ArrayCollection();
    }

    #[ORM\PrePersist]
    public function onPrePersist(): void
    {
        $this->createdAt = new \DateTimeImmutable();
        $this->updatedAt = new \DateTimeImmutable();
    }

    #[ORM\PreUpdate]
    public function onPreUpdate(): void
    {
        $this->updatedAt = new \DateTimeImmutable();
    }

    // Getters and setters...
}
```

### 3. Custom State Provider and Processor

```php
<?php

namespace App\State;

use ApiPlatform\Metadata\Operation;
use ApiPlatform\State\ProviderInterface;
use App\Repository\UserRepository;
use Symfony\Component\HttpKernel\Exception\NotFoundHttpException;

final class UserProvider implements ProviderInterface
{
    public function __construct(
        private readonly UserRepository $userRepository,
        private readonly ProviderInterface $decorated
    ) {}

    public function provide(Operation $operation, array $uriVariables = [], array $context = []): object|array|null
    {
        if ($operation->getName() === 'get_by_email') {
            $email = $uriVariables['email'] ?? null;
            
            if (!$email) {
                throw new NotFoundHttpException('Email parameter is required');
            }
            
            $user = $this->userRepository->findOneBy(['email' => $email]);
            
            if (!$user) {
                throw new NotFoundHttpException('User not found');
            }
            
            return $user;
        }

        return $this->decorated->provide($operation, $uriVariables, $context);
    }
}

// State Processor
namespace App\State;

use ApiPlatform\Metadata\Operation;
use ApiPlatform\State\ProcessorInterface;
use App\Entity\User;
use App\Message\UserRegisteredMessage;
use App\Service\EmailService;
use Symfony\Component\Messenger\MessageBusInterface;
use Symfony\Component\PasswordHasher\Hasher\UserPasswordHasherInterface;

final class UserPasswordHasher implements ProcessorInterface
{
    public function __construct(
        private readonly ProcessorInterface $decorated,
        private readonly UserPasswordHasherInterface $passwordHasher,
        private readonly MessageBusInterface $messageBus,
        private readonly EmailService $emailService
    ) {}

    public function process(mixed $data, Operation $operation, array $uriVariables = [], array $context = []): mixed
    {
        if ($data instanceof User && $data->getPlainPassword()) {
            $hashedPassword = $this->passwordHasher->hashPassword($data, $data->getPlainPassword());
            $data->setPassword($hashedPassword);
            $data->eraseCredentials();
        }

        $result = $this->decorated->process($data, $operation, $uriVariables, $context);

        if ($operation->getName() === 'post' && $result instanceof User) {
            // Send async message for welcome email
            $this->messageBus->dispatch(new UserRegisteredMessage($result->getId()));
            
            // Send immediate confirmation
            $this->emailService->sendRegistrationConfirmation($result);
        }

        return $result;
    }
}
```

### 4. Custom Filters

```php
<?php

namespace App\Filter;

use ApiPlatform\Doctrine\Orm\Filter\AbstractFilter;
use ApiPlatform\Doctrine\Orm\Util\QueryNameGeneratorInterface;
use ApiPlatform\Metadata\Operation;
use Doctrine\ORM\QueryBuilder;
use Symfony\Component\PropertyInfo\Type;

final class CustomSearchFilter extends AbstractFilter
{
    protected function filterProperty(
        string $property,
        mixed $value,
        QueryBuilder $queryBuilder,
        QueryNameGeneratorInterface $queryNameGenerator,
        string $resourceClass,
        Operation $operation = null,
        array $context = []
    ): void {
        if ($property !== 'search') {
            return;
        }

        $alias = $queryBuilder->getRootAliases()[0];
        $valueParameter = $queryNameGenerator->generateParameterName('search');

        $queryBuilder
            ->andWhere(sprintf(
                '%s.name LIKE :%s OR %s.description LIKE :%s OR %s.sku LIKE :%s',
                $alias,
                $valueParameter,
                $alias,
                $valueParameter,
                $alias,
                $valueParameter
            ))
            ->setParameter($valueParameter, '%' . $value . '%');
    }

    public function getDescription(string $resourceClass): array
    {
        return [
            'search' => [
                'property' => null,
                'type' => Type::BUILTIN_TYPE_STRING,
                'required' => false,
                'description' => 'Search in name, description, and SKU',
            ],
        ];
    }
}
```

### 5. Security and Voters

```php
<?php

namespace App\Security\Voter;

use App\Entity\User;
use Symfony\Bundle\SecurityBundle\Security;
use Symfony\Component\Security\Core\Authentication\Token\TokenInterface;
use Symfony\Component\Security\Core\Authorization\Voter\Voter;

class UserVoter extends Voter
{
    public const VIEW = 'USER_VIEW';
    public const EDIT = 'USER_EDIT';
    public const DELETE = 'USER_DELETE';

    public function __construct(
        private readonly Security $security
    ) {}

    protected function supports(string $attribute, mixed $subject): bool
    {
        return in_array($attribute, [self::VIEW, self::EDIT, self::DELETE])
            && $subject instanceof User;
    }

    protected function voteOnAttribute(string $attribute, mixed $subject, TokenInterface $token): bool
    {
        $user = $token->getUser();

        if (!$user instanceof User) {
            return false;
        }

        // Admin can do everything
        if ($this->security->isGranted('ROLE_ADMIN')) {
            return true;
        }

        /** @var User $targetUser */
        $targetUser = $subject;

        return match ($attribute) {
            self::VIEW => $this->canView($targetUser, $user),
            self::EDIT => $this->canEdit($targetUser, $user),
            self::DELETE => $this->canDelete($targetUser, $user),
            default => false,
        };
    }

    private function canView(User $targetUser, User $user): bool
    {
        // Users can view their own profile
        return $user->getId() === $targetUser->getId();
    }

    private function canEdit(User $targetUser, User $user): bool
    {
        // Users can edit their own profile
        return $user->getId() === $targetUser->getId();
    }

    private function canDelete(User $targetUser, User $user): bool
    {
        // Only admins can delete users
        return false;
    }
}
```

### 6. Custom Normalizer

```php
<?php

namespace App\Serializer\Normalizer;

use App\Entity\Product;
use Symfony\Component\Serializer\Normalizer\NormalizerInterface;
use Symfony\Component\Serializer\Normalizer\NormalizerAwareInterface;
use Symfony\Component\Serializer\Normalizer\NormalizerAwareTrait;

class ProductNormalizer implements NormalizerInterface, NormalizerAwareInterface
{
    use NormalizerAwareTrait;

    private const ALREADY_CALLED = 'PRODUCT_NORMALIZER_ALREADY_CALLED';

    public function normalize(mixed $object, string $format = null, array $context = []): array
    {
        $context[self::ALREADY_CALLED] = true;

        /** @var Product $object */
        $data = $this->normalizer->normalize($object, $format, $context);

        // Add computed fields
        $data['displayPrice'] = '$' . number_format((float) $object->getPrice(), 2);
        $data['inStock'] = $object->getStock() > 0;
        $data['availability'] = $this->getAvailabilityStatus($object);

        // Add related data count
        if ($object->getImages()) {
            $data['imageCount'] = $object->getImages()->count();
        }

        return $data;
    }

    public function supportsNormalization(mixed $data, string $format = null, array $context = []): bool
    {
        return !isset($context[self::ALREADY_CALLED]) && $data instanceof Product;
    }

    private function getAvailabilityStatus(Product $product): string
    {
        if ($product->getStock() === 0) {
            return 'out_of_stock';
        }
        
        if ($product->getStock() < 10) {
            return 'low_stock';
        }
        
        return 'in_stock';
    }
}
```

### 7. Repository Pattern

```php
<?php

namespace App\Repository;

use App\Entity\Product;
use Doctrine\Bundle\DoctrineBundle\Repository\ServiceEntityRepository;
use Doctrine\ORM\QueryBuilder;
use Doctrine\Persistence\ManagerRegistry;

/**
 * @extends ServiceEntityRepository<Product>
 * @method Product|null find($id, $lockMode = null, $lockVersion = null)
 * @method Product|null findOneBy(array $criteria, array $orderBy = null)
 * @method Product[]    findAll()
 * @method Product[]    findBy(array $criteria, array $orderBy = null, $limit = null, $offset = null)
 */
class ProductRepository extends ServiceEntityRepository
{
    public function __construct(ManagerRegistry $registry)
    {
        parent::__construct($registry, Product::class);
    }

    public function createQueryBuilderWithAssociations(): QueryBuilder
    {
        return $this->createQueryBuilder('p')
            ->leftJoin('p.category', 'c')
            ->leftJoin('p.tags', 't')
            ->leftJoin('p.images', 'i')
            ->addSelect('c', 't', 'i');
    }

    public function findActiveProducts(): array
    {
        return $this->createQueryBuilderWithAssociations()
            ->where('p.status = :status')
            ->setParameter('status', 'active')
            ->orderBy('p.createdAt', 'DESC')
            ->getQuery()
            ->getResult();
    }

    public function findByCategoryWithStock(int $categoryId): array
    {
        return $this->createQueryBuilder('p')
            ->where('p.category = :categoryId')
            ->andWhere('p.stock > 0')
            ->andWhere('p.status = :status')
            ->setParameter('categoryId', $categoryId)
            ->setParameter('status', 'active')
            ->orderBy('p.name', 'ASC')
            ->getQuery()
            ->getResult();
    }

    public function searchProducts(string $term): array
    {
        $qb = $this->createQueryBuilderWithAssociations();

        return $qb
            ->where($qb->expr()->orX(
                $qb->expr()->like('LOWER(p.name)', ':term'),
                $qb->expr()->like('LOWER(p.description)', ':term'),
                $qb->expr()->like('LOWER(p.sku)', ':term')
            ))
            ->setParameter('term', '%' . strtolower($term) . '%')
            ->getQuery()
            ->getResult();
    }

    public function updateStock(int $productId, int $quantity): void
    {
        $this->createQueryBuilder('p')
            ->update()
            ->set('p.stock', 'p.stock + :quantity')
            ->set('p.updatedAt', ':now')
            ->where('p.id = :id')
            ->setParameter('quantity', $quantity)
            ->setParameter('id', $productId)
            ->setParameter('now', new \DateTimeImmutable())
            ->getQuery()
            ->execute();
    }
}
```

### 8. Testing

```php
<?php

namespace App\Tests\Api;

use ApiPlatform\Symfony\Bundle\Test\ApiTestCase;
use App\Entity\User;
use App\Factory\UserFactory;
use Symfony\Component\HttpFoundation\Response;
use Zenstruck\Foundry\Test\Factories;
use Zenstruck\Foundry\Test\ResetDatabase;

class UserResourceTest extends ApiTestCase
{
    use ResetDatabase;
    use Factories;

    public function testGetCollection(): void
    {
        UserFactory::createMany(5);

        $response = static::createClient()->request('GET', '/api/users');

        $this->assertResponseIsSuccessful();
        $this->assertResponseHeaderSame('content-type', 'application/ld+json; charset=utf-8');
        $this->assertJsonContains([
            '@context' => '/api/contexts/User',
            '@id' => '/api/users',
            '@type' => 'hydra:Collection',
            'hydra:totalItems' => 5,
        ]);
    }

    public function testCreateUser(): void
    {
        $client = static::createClient();

        $response = $client->request('POST', '/api/users', [
            'json' => [
                'email' => 'test@example.com',
                'plainPassword' => 'password123',
                'firstName' => 'John',
                'lastName' => 'Doe',
            ],
        ]);

        $this->assertResponseStatusCodeSame(Response::HTTP_CREATED);
        $this->assertJsonContains([
            '@type' => 'User',
            'email' => 'test@example.com',
            'firstName' => 'John',
            'lastName' => 'Doe',
        ]);
    }

    public function testUpdateUser(): void
    {
        $user = UserFactory::createOne([
            'email' => 'existing@example.com',
        ]);

        $client = static::createClient();
        $this->loginAs($user->object());

        $response = $client->request('PUT', '/api/users/' . $user->getId(), [
            'json' => [
                'firstName' => 'Updated',
            ],
        ]);

        $this->assertResponseIsSuccessful();
        $this->assertJsonContains([
            'firstName' => 'Updated',
        ]);
    }

    public function testDeleteUserRequiresAdmin(): void
    {
        $user = UserFactory::createOne();
        $admin = UserFactory::createOne(['roles' => ['ROLE_ADMIN']]);

        $client = static::createClient();
        
        // Try as regular user - should fail
        $this->loginAs($user->object());
        $client->request('DELETE', '/api/users/' . $user->getId());
        $this->assertResponseStatusCodeSame(Response::HTTP_FORBIDDEN);

        // Try as admin - should succeed
        $this->loginAs($admin->object());
        $client->request('DELETE', '/api/users/' . $user->getId());
        $this->assertResponseStatusCodeSame(Response::HTTP_NO_CONTENT);
    }

    private function loginAs(User $user): void
    {
        $client = static::getClient();
        $client->loginUser($user);
    }
}
```

### 9. Services Configuration

```yaml
# config/services.yaml
parameters:
    app.upload_directory: '%kernel.project_dir%/public/uploads'

services:
    _defaults:
        autowire: true
        autoconfigure: true

    App\:
        resource: '../src/'
        exclude:
            - '../src/DependencyInjection/'
            - '../src/Entity/'
            - '../src/Kernel.php'

    # Custom services
    App\Service\FileUploader:
        arguments:
            $targetDirectory: '%app.upload_directory%'

    App\State\UserPasswordHasher:
        bind:
            $decorated: '@api_platform.doctrine.orm.state.persist_processor'

    App\State\UserProvider:
        bind:
            $decorated: '@api_platform.doctrine.orm.state.item_provider'

    # Event subscribers
    App\EventSubscriber\:
        resource: '../src/EventSubscriber/'
        tags: ['kernel.event_subscriber']
```

### Common Pitfalls to Avoid

1. **Not using DTOs for complex operations**
2. **Exposing sensitive data in API responses**
3. **Not implementing proper pagination**
4. **Ignoring N+1 query problems**
5. **Not using proper validation groups**
6. **Forgetting to handle circular references**
7. **Not implementing proper caching**
8. **Using entities directly as API resources**
9. **Not handling API versioning**
10. **Ignoring performance optimization**

### Useful Bundles

- **api-platform/core**: API Platform core
- **doctrine/orm**: Database ORM
- **symfony/security-bundle**: Authentication & authorization
- **lexik/jwt-authentication-bundle**: JWT authentication
- **nelmio/cors-bundle**: CORS handling
- **symfony/messenger**: Async message handling
- **vich/uploader-bundle**: File uploads
- **stof/doctrine-extensions-bundle**: Doctrine extensions
- **symfony/webpack-encore-bundle**: Asset management
- **friendsofsymfony/elastica-bundle**: Elasticsearch integration