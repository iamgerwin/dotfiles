# Meteor.js Best Practices

## Overview
Meteor is a full-stack JavaScript platform for building web and mobile applications in pure JavaScript. It provides real-time data synchronization, hot code push, and integrated build tooling.

## Documentation
- [Official Documentation](https://docs.meteor.com)
- [Meteor Guide](https://guide.meteor.com)
- [API Documentation](https://docs.meteor.com/api/core.html)
- [Meteor Forums](https://forums.meteor.com)
- [Atmosphere Packages](https://atmospherejs.com)

## Project Structure

```
project-root/
├── client/
│   ├── main.js
│   ├── main.html
│   ├── main.css
│   └── components/
├── server/
│   ├── main.js
│   ├── publications/
│   └── fixtures/
├── imports/
│   ├── api/
│   │   ├── users/
│   │   │   ├── users.js
│   │   │   ├── methods.js
│   │   │   ├── publications.js
│   │   │   └── server/
│   │   └── tasks/
│   ├── ui/
│   │   ├── components/
│   │   ├── layouts/
│   │   └── pages/
│   └── startup/
│       ├── client/
│       └── server/
├── public/
├── private/
├── tests/
├── .meteor/
├── package.json
└── settings.json
```

## Core Best Practices

### 1. Collections and Schemas

```javascript
// imports/api/tasks/tasks.js
import { Mongo } from 'meteor/mongo';
import SimpleSchema from 'simpl-schema';

export const Tasks = new Mongo.Collection('tasks');

// Define schema for validation
Tasks.schema = new SimpleSchema({
  title: {
    type: String,
    max: 200,
  },
  description: {
    type: String,
    optional: true,
    max: 1000,
  },
  completed: {
    type: Boolean,
    defaultValue: false,
  },
  userId: {
    type: String,
    regEx: SimpleSchema.RegEx.Id,
  },
  createdAt: {
    type: Date,
    autoValue() {
      if (this.isInsert) {
        return new Date();
      }
    },
  },
  updatedAt: {
    type: Date,
    autoValue() {
      return new Date();
    },
  },
  priority: {
    type: String,
    allowedValues: ['low', 'medium', 'high'],
    defaultValue: 'medium',
  },
  tags: {
    type: Array,
    optional: true,
  },
  'tags.$': {
    type: String,
  },
});

// Attach schema to collection
Tasks.attachSchema(Tasks.schema);

// Helpers
Tasks.helpers({
  owner() {
    return Meteor.users.findOne(this.userId);
  },
  isOverdue() {
    return this.dueDate && this.dueDate < new Date() && !this.completed;
  },
});

// Collection hooks
Tasks.before.insert((userId, doc) => {
  doc.createdAt = new Date();
  doc.userId = userId;
});
```

### 2. Methods (RPC Calls)

```javascript
// imports/api/tasks/methods.js
import { Meteor } from 'meteor/meteor';
import { check, Match } from 'meteor/check';
import { Tasks } from './tasks.js';
import { ValidatedMethod } from 'meteor/mdg:validated-method';
import { RateLimiterMixin } from 'ddp-rate-limiter-mixin';

export const insertTask = new ValidatedMethod({
  name: 'tasks.insert',
  mixins: [RateLimiterMixin],
  rateLimit: {
    numRequests: 5,
    timeInterval: 1000,
  },
  validate: new SimpleSchema({
    title: String,
    description: {
      type: String,
      optional: true,
    },
    priority: {
      type: String,
      allowedValues: ['low', 'medium', 'high'],
    },
  }).validator(),
  run({ title, description, priority }) {
    if (!this.userId) {
      throw new Meteor.Error('tasks.insert.notLoggedIn',
        'Must be logged in to create a task.');
    }

    const task = {
      title,
      description,
      priority,
      userId: this.userId,
      completed: false,
      createdAt: new Date(),
    };

    return Tasks.insert(task);
  },
});

export const updateTask = new ValidatedMethod({
  name: 'tasks.update',
  validate: new SimpleSchema({
    taskId: String,
    updates: Object,
    'updates.title': {
      type: String,
      optional: true,
    },
    'updates.description': {
      type: String,
      optional: true,
    },
    'updates.completed': {
      type: Boolean,
      optional: true,
    },
  }).validator(),
  run({ taskId, updates }) {
    const task = Tasks.findOne(taskId);
    
    if (!task) {
      throw new Meteor.Error('tasks.update.notFound',
        'Task not found');
    }
    
    if (task.userId !== this.userId) {
      throw new Meteor.Error('tasks.update.unauthorized',
        'Cannot edit tasks that are not yours');
    }

    Tasks.update(taskId, {
      $set: updates,
    });
  },
});

// Traditional Meteor methods
Meteor.methods({
  'tasks.remove'(taskId) {
    check(taskId, String);
    
    if (!this.userId) {
      throw new Meteor.Error('not-authorized');
    }
    
    const task = Tasks.findOne(taskId);
    if (task.userId !== this.userId) {
      throw new Meteor.Error('not-authorized');
    }
    
    Tasks.remove(taskId);
  },
  
  'tasks.setCompleted'(taskId, completed) {
    check(taskId, String);
    check(completed, Boolean);
    
    const task = Tasks.findOne(taskId);
    
    if (task.userId !== this.userId) {
      throw new Meteor.Error('not-authorized');
    }
    
    Tasks.update(taskId, { $set: { completed } });
  },
});
```

### 3. Publications and Subscriptions

```javascript
// imports/api/tasks/publications.js
import { Meteor } from 'meteor/meteor';
import { Tasks } from './tasks.js';
import { check } from 'meteor/check';

// Simple publication
Meteor.publish('tasks.all', function() {
  if (!this.userId) {
    return this.ready();
  }
  
  return Tasks.find({ userId: this.userId });
});

// Publication with parameters
Meteor.publish('tasks.byStatus', function(completed) {
  check(completed, Boolean);
  
  if (!this.userId) {
    return this.ready();
  }
  
  return Tasks.find({
    userId: this.userId,
    completed,
  });
});

// Complex publication with joins
Meteor.publish('tasks.withOwner', function(limit = 10) {
  check(limit, Match.Integer);
  
  if (!this.userId) {
    return this.ready();
  }
  
  const tasks = Tasks.find(
    { userId: this.userId },
    { 
      limit,
      sort: { createdAt: -1 }
    }
  );
  
  const userIds = tasks.map(task => task.userId);
  
  return [
    tasks,
    Meteor.users.find(
      { _id: { $in: userIds } },
      { fields: { username: 1, emails: 1 } }
    ),
  ];
});

// Reactive publication
Meteor.publish('tasks.reactive', function() {
  const self = this;
  let count = 0;
  
  const handle = Tasks.find({ userId: this.userId }).observeChanges({
    added(id, fields) {
      count++;
      self.added('task-counts', 'count', { count });
      self.added('tasks', id, fields);
    },
    removed(id) {
      count--;
      self.changed('task-counts', 'count', { count });
      self.removed('tasks', id);
    },
  });
  
  self.ready();
  
  self.onStop(() => {
    handle.stop();
  });
});
```

### 4. React Integration

```javascript
// imports/ui/components/TaskList.jsx
import React, { useState } from 'react';
import { useTracker } from 'meteor/react-meteor-data';
import { Tasks } from '../../api/tasks/tasks';
import { insertTask, updateTask } from '../../api/tasks/methods';

export const TaskList = () => {
  const [filter, setFilter] = useState('all');
  
  const { tasks, isLoading, user } = useTracker(() => {
    const noDataAvailable = { tasks: [], isLoading: false };
    
    if (!Meteor.user()) {
      return noDataAvailable;
    }
    
    const handler = Meteor.subscribe('tasks.all');
    
    if (!handler.ready()) {
      return { ...noDataAvailable, isLoading: true };
    }
    
    const query = filter === 'completed' 
      ? { completed: true }
      : filter === 'active'
      ? { completed: false }
      : {};
    
    const tasks = Tasks.find(query, {
      sort: { createdAt: -1 }
    }).fetch();
    
    return {
      tasks,
      isLoading: false,
      user: Meteor.user(),
    };
  });
  
  const handleAddTask = (title) => {
    insertTask.call({
      title,
      priority: 'medium',
    }, (error) => {
      if (error) {
        alert(error.message);
      }
    });
  };
  
  const handleToggleComplete = (task) => {
    updateTask.call({
      taskId: task._id,
      updates: {
        completed: !task.completed,
      },
    });
  };
  
  if (isLoading) {
    return <div>Loading...</div>;
  }
  
  return (
    <div className="task-list">
      <TaskForm onSubmit={handleAddTask} />
      <FilterButtons filter={filter} onFilterChange={setFilter} />
      
      <ul>
        {tasks.map(task => (
          <TaskItem
            key={task._id}
            task={task}
            onToggleComplete={() => handleToggleComplete(task)}
          />
        ))}
      </ul>
    </div>
  );
};

// With withTracker HOC (legacy)
import { withTracker } from 'meteor/react-meteor-data';

const TaskListComponent = ({ tasks, isLoading }) => {
  // Component logic
};

export default withTracker(() => {
  const handle = Meteor.subscribe('tasks.all');
  
  return {
    tasks: Tasks.find({}, { sort: { createdAt: -1 } }).fetch(),
    isLoading: !handle.ready(),
  };
})(TaskListComponent);
```

### 5. Vue Integration

```javascript
// imports/ui/components/TaskList.vue
<template>
  <div class="task-list">
    <task-form @submit="handleAddTask" />
    
    <div v-if="$subReady.tasks">
      <task-item
        v-for="task in tasks"
        :key="task._id"
        :task="task"
        @toggle="handleToggleComplete"
      />
    </div>
    <div v-else>
      Loading...
    </div>
  </div>
</template>

<script>
import { Tasks } from '../../api/tasks/tasks';
import { insertTask, updateTask } from '../../api/tasks/methods';

export default {
  name: 'TaskList',
  
  meteor: {
    $subscribe: {
      'tasks': []
    },
    
    tasks() {
      return Tasks.find({}, {
        sort: { createdAt: -1 }
      }).fetch();
    },
    
    currentUser() {
      return Meteor.user();
    }
  },
  
  methods: {
    handleAddTask(title) {
      insertTask.call({
        title,
        priority: 'medium'
      }, (error) => {
        if (error) {
          this.$notify.error(error.message);
        }
      });
    },
    
    handleToggleComplete(task) {
      updateTask.call({
        taskId: task._id,
        updates: {
          completed: !task.completed
        }
      });
    }
  }
};
</script>
```

### 6. Security

```javascript
// server/security.js
import { Meteor } from 'meteor/meteor';
import { Tasks } from '../imports/api/tasks/tasks';

// Remove insecure package and define allow/deny rules
Tasks.allow({
  insert(userId, doc) {
    // Only allow inserting if user is logged in
    return userId && doc.userId === userId;
  },
  
  update(userId, doc, fieldNames, modifier) {
    // Can only change your own documents
    return doc.userId === userId;
  },
  
  remove(userId, doc) {
    // Can only remove your own documents
    return doc.userId === userId;
  }
});

// Deny rules override allow rules
Tasks.deny({
  update(userId, doc, fieldNames) {
    // Can't change owners
    return fieldNames.includes('userId');
  }
});

// Field-level security
Tasks.deny({
  update(userId, doc, fieldNames) {
    // Deny updating certain fields
    const deniedFields = ['createdAt', 'userId'];
    return fieldNames.some(field => deniedFields.includes(field));
  }
});
```

### 7. Authentication

```javascript
// imports/ui/components/Login.jsx
import React, { useState } from 'react';
import { Meteor } from 'meteor/meteor';
import { Accounts } from 'meteor/accounts-base';

export const Login = () => {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [isSignup, setIsSignup] = useState(false);
  
  const handleSubmit = (e) => {
    e.preventDefault();
    
    if (isSignup) {
      Accounts.createUser({
        email,
        password,
        profile: {
          name: email.split('@')[0]
        }
      }, (error) => {
        if (error) {
          alert(error.reason);
        }
      });
    } else {
      Meteor.loginWithPassword(email, password, (error) => {
        if (error) {
          alert(error.reason);
        }
      });
    }
  };
  
  const handleOAuthLogin = (service) => {
    const loginMethod = {
      google: Meteor.loginWithGoogle,
      facebook: Meteor.loginWithFacebook,
      github: Meteor.loginWithGithub,
    }[service];
    
    loginMethod({
      requestPermissions: service === 'google' ? ['email'] : []
    }, (error) => {
      if (error) {
        alert(error.reason);
      }
    });
  };
  
  return (
    <form onSubmit={handleSubmit}>
      <input
        type="email"
        placeholder="Email"
        value={email}
        onChange={(e) => setEmail(e.target.value)}
        required
      />
      
      <input
        type="password"
        placeholder="Password"
        value={password}
        onChange={(e) => setPassword(e.target.value)}
        required
      />
      
      <button type="submit">
        {isSignup ? 'Sign Up' : 'Log In'}
      </button>
      
      <button type="button" onClick={() => setIsSignup(!isSignup)}>
        {isSignup ? 'Have an account? Log In' : 'Need an account? Sign Up'}
      </button>
      
      <div className="oauth-buttons">
        <button type="button" onClick={() => handleOAuthLogin('google')}>
          Login with Google
        </button>
        <button type="button" onClick={() => handleOAuthLogin('github')}>
          Login with GitHub
        </button>
      </div>
    </form>
  );
};
```

### 8. Testing

```javascript
// imports/api/tasks/tasks.test.js
import { Meteor } from 'meteor/meteor';
import { Random } from 'meteor/random';
import { assert } from 'chai';
import { Tasks } from './tasks.js';
import { insertTask, updateTask } from './methods.js';

if (Meteor.isServer) {
  describe('Tasks', () => {
    describe('methods', () => {
      const userId = Random.id();
      let taskId;
      
      beforeEach(() => {
        Tasks.remove({});
        taskId = Tasks.insert({
          title: 'Test task',
          userId,
          createdAt: new Date(),
        });
      });
      
      it('can insert a task', () => {
        const insertTaskMethod = Meteor.server.method_handlers['tasks.insert'];
        
        const invocation = { userId };
        
        insertTaskMethod.apply(invocation, [{
          title: 'New task',
          priority: 'high'
        }]);
        
        assert.equal(Tasks.find().count(), 2);
      });
      
      it('cannot insert task when not logged in', () => {
        const insertTaskMethod = Meteor.server.method_handlers['tasks.insert'];
        
        const invocation = {};
        
        assert.throws(() => {
          insertTaskMethod.apply(invocation, [{
            title: 'New task',
            priority: 'high'
          }]);
        }, Meteor.Error);
      });
    });
    
    describe('publications', () => {
      it('publishes user tasks', (done) => {
        const collector = new PublicationCollector({ userId });
        
        collector.collect('tasks.all', (collections) => {
          assert.equal(collections.tasks.length, 1);
          done();
        });
      });
    });
  });
}

// Client-side testing with mocha
describe('Task component', () => {
  it('renders correctly', () => {
    const task = {
      _id: '1',
      title: 'Test task',
      completed: false
    };
    
    const wrapper = mount(<TaskItem task={task} />);
    
    expect(wrapper.find('.task-title').text()).toBe('Test task');
    expect(wrapper.find('input[type="checkbox"]').prop('checked')).toBe(false);
  });
});
```

## Performance Optimization

### 1. Subscription Management

```javascript
// Use subscription caching
const subsCache = new SubsCache({
  expireAfter: 5, // minutes
  cacheLimit: 10
});

// In component
const handle = subsCache.subscribe('tasks.all');

// Stop subscriptions when not needed
Template.taskList.onDestroyed(function() {
  this.subscription.stop();
});
```

### 2. Data Optimization

```javascript
// Use field limiting in publications
Meteor.publish('tasks.minimal', function() {
  return Tasks.find(
    { userId: this.userId },
    { 
      fields: { 
        title: 1, 
        completed: 1 
      },
      limit: 100
    }
  );
});

// Use aggregation for complex queries
Tasks.rawCollection().aggregate([
  { $match: { userId: this.userId } },
  { $group: { 
    _id: '$priority', 
    count: { $sum: 1 } 
  }}
]).toArray();
```

### 3. Method Optimization

```javascript
// Use unblock for long-running methods
Meteor.methods({
  'tasks.longRunning'() {
    this.unblock(); // Allow other methods to run
    
    // Long-running operation
    const result = HTTP.get('https://api.example.com/data');
    
    return result.data;
  }
});
```

## Deployment

### 1. Production Settings

```json
{
  "public": {
    "environment": "production",
    "analyticsKey": "your-analytics-key"
  },
  "private": {
    "oauth": {
      "google": {
        "clientId": "your-client-id",
        "secret": "your-secret"
      }
    }
  },
  "galaxy.meteor.com": {
    "env": {
      "MONGO_URL": "mongodb://...",
      "ROOT_URL": "https://myapp.com"
    }
  }
}
```

### 2. Deployment Commands

```bash
# Deploy to Meteor Galaxy
meteor deploy myapp.meteorapp.com --settings settings.json

# Deploy with custom domain
meteor deploy www.myapp.com --settings settings.json

# Deploy to custom server with Meteor Up
npm install -g mup
mup init
mup setup
mup deploy
```

## Common Pitfalls

1. **Publication Memory Leaks**: Not stopping observers
2. **Subscription Flooding**: Too many subscriptions
3. **Method Rate Limiting**: Not implementing rate limits
4. **Insecure Defaults**: Forgetting to remove insecure/autopublish
5. **Client-side Security**: Trusting client data
6. **Reactive Computations**: Creating unnecessary reactivity

## Useful Packages

- **aldeed:collection2**: Schema validation
- **mdg:validated-method**: Better method definitions
- **reywood:publish-composite**: Reactive joins
- **meteorhacks:aggregate**: MongoDB aggregation
- **percolate:migrations**: Database migrations
- **alanning:roles**: Role-based permissions
- **cultofcoders:redis-oplog**: Redis for scalability
- **meteorhacks:kadira**: Performance monitoring