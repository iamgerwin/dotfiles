# Security Frameworks Best Practices

## Overview

This document provides best practices for implementing battle-tested security frameworks that meet government standards and enterprise compliance requirements. These frameworks ensure robust, hack-proof applications through industry-standard security controls.

## NIST Cybersecurity Framework

### Core Functions Implementation

```yaml
# NIST Framework Implementation
identify:
  asset_management:
    - inventory_systems: "Complete asset inventory"
    - data_classification: "Sensitive data mapping"
    - risk_assessment: "Regular vulnerability assessments"
  
protect:
    access_control: "Role-based access control (RBAC)"
    awareness_training: "Security awareness programs"
    data_security: "Encryption at rest and in transit"
    
detect:
    monitoring: "24/7 security monitoring"
    detection_processes: "Automated threat detection"
    
respond:
    incident_response: "Incident response procedures"
    communication: "Stakeholder notification protocols"
    
recover:
    recovery_planning: "Business continuity plans"
    improvements: "Lessons learned integration"
```

### Implementation Code

```typescript
// NIST-compliant logging system
class NISTSecurityLogger {
  private static readonly RISK_LEVELS = {
    LOW: 'low',
    MODERATE: 'moderate',
    HIGH: 'high'
  } as const;

  static logSecurityEvent(event: SecurityEvent): void {
    const logEntry = {
      timestamp: new Date().toISOString(),
      eventType: event.type,
      severity: this.calculateSeverity(event),
      source: event.source,
      details: this.sanitizeDetails(event.details),
      nistFunction: this.mapToNISTFunction(event.type)
    };
    
    this.persistLog(logEntry);
    this.alertIfCritical(logEntry);
  }

  private static mapToNISTFunction(eventType: string): string {
    const mapping: Record<string, string> = {
      'login_attempt': 'IDENTIFY',
      'data_access': 'PROTECT',
      'anomaly_detected': 'DETECT',
      'incident_reported': 'RESPOND',
      'system_restored': 'RECOVER'
    };
    return mapping[eventType] || 'UNKNOWN';
  }
}
```

## ISO 27001 Information Security Management

### ISMS Implementation

```typescript
// ISO 27001 Risk Management
class ISO27001RiskManager {
  private riskRegister: RiskEntry[] = [];

  assessRisk(asset: Asset, threat: Threat, vulnerability: Vulnerability): RiskAssessment {
    const impact = this.calculateImpact(asset, threat);
    const likelihood = this.calculateLikelihood(threat, vulnerability);
    const riskLevel = this.calculateRiskLevel(impact, likelihood);
    
    const assessment: RiskAssessment = {
      id: generateUUID(),
      asset: asset,
      threat: threat,
      vulnerability: vulnerability,
      impact: impact,
      likelihood: likelihood,
      riskLevel: riskLevel,
      controls: this.recommendControls(riskLevel),
      assessmentDate: new Date(),
      nextReviewDate: this.calculateNextReview(riskLevel)
    };
    
    this.riskRegister.push({
      assessment,
      status: 'IDENTIFIED',
      owner: this.assignRiskOwner(asset),
      treatmentPlan: null
    });
    
    return assessment;
  }

  private recommendControls(riskLevel: RiskLevel): SecurityControl[] {
    const controlSets: Record<RiskLevel, SecurityControl[]> = {
      HIGH: [
        { id: 'A.9.1.1', name: 'Access Control Policy', mandatory: true },
        { id: 'A.12.6.1', name: 'Management of Technical Vulnerabilities', mandatory: true },
        { id: 'A.16.1.1', name: 'Responsibilities and Procedures', mandatory: true }
      ],
      MEDIUM: [
        { id: 'A.8.2.1', name: 'Classification of Information', mandatory: false },
        { id: 'A.11.2.1', name: 'Physical Entry Controls', mandatory: false }
      ],
      LOW: [
        { id: 'A.7.2.2', name: 'Information Security Awareness', mandatory: false }
      ]
    };
    return controlSets[riskLevel] || [];
  }
}
```

### Annex A Controls Implementation

```typescript
// ISO 27001 Annex A.9 - Access Control
class AccessControlManager {
  private policies: AccessPolicy[] = [];
  private userRoles: Map<string, Role[]> = new Map();

  enforceAccessControl(user: User, resource: Resource, action: string): boolean {
    // A.9.1.1 Access Control Policy
    const applicablePolicies = this.getApplicablePolicies(resource);
    
    // A.9.2.1 User Registration and De-registration
    if (!this.isUserActive(user)) {
      this.logSecurityEvent('UNAUTHORIZED_ACCESS_ATTEMPT', user, resource);
      return false;
    }

    // A.9.2.3 Management of Privileged Access Rights
    if (this.requiresPrivilegedAccess(action)) {
      return this.validatePrivilegedAccess(user, resource, action);
    }

    // A.9.4.1 Information Access Restriction
    return this.validateStandardAccess(user, resource, action, applicablePolicies);
  }

  private validatePrivilegedAccess(user: User, resource: Resource, action: string): boolean {
    const privilegedRoles = this.userRoles.get(user.id)?.filter(role => role.privileged) || [];
    const requiredPrivileges = this.getRequiredPrivileges(resource, action);
    
    const hasRequiredPrivileges = requiredPrivileges.every(privilege =>
      privilegedRoles.some(role => role.permissions.includes(privilege))
    );

    if (hasRequiredPrivileges) {
      // A.9.2.5 Review of User Access Rights
      this.scheduleAccessReview(user, resource);
      this.logPrivilegedAccess(user, resource, action);
    }

    return hasRequiredPrivileges;
  }
}
```

## OWASP Security Standards

### OWASP Top 10 Mitigation

```typescript
// OWASP Top 10 2021 Protection Implementation
class OWASPProtectionMiddleware {
  // A01:2021 - Broken Access Control
  static validateAccessControl(req: Request, res: Response, next: NextFunction): void {
    const user = req.user;
    const resource = req.params.resource;
    const action = req.method;

    if (!AccessControlManager.hasPermission(user, resource, action)) {
      res.status(403).json({ error: 'Access denied' });
      SecurityLogger.logAccessViolation(user, resource, action);
      return;
    }
    next();
  }

  // A02:2021 - Cryptographic Failures
  static encryptSensitiveData(data: any): string {
    const algorithm = 'aes-256-gcm';
    const key = process.env.ENCRYPTION_KEY;
    const iv = crypto.randomBytes(16);
    
    const cipher = crypto.createCipher(algorithm, key, iv);
    let encrypted = cipher.update(JSON.stringify(data), 'utf8', 'hex');
    encrypted += cipher.final('hex');
    
    const authTag = cipher.getAuthTag();
    return `${iv.toString('hex')}:${authTag.toString('hex')}:${encrypted}`;
  }

  // A03:2021 - Injection
  static validateInput(input: any, schema: ValidationSchema): ValidationResult {
    // SQL Injection Prevention
    const sqlInjectionPattern = /(union|select|insert|delete|update|drop|create|alter|exec|execute)/i;
    
    // XSS Prevention
    const xssPattern = /<script\b[^<]*(?:(?!<\/script>)<[^<]*)*<\/script>/gi;
    
    // Command Injection Prevention
    const commandInjectionPattern = /[;&|`$(){}[\]]/;

    const sanitized = DOMPurify.sanitize(input);
    
    if (sqlInjectionPattern.test(sanitized) || 
        xssPattern.test(sanitized) || 
        commandInjectionPattern.test(sanitized)) {
      return { valid: false, error: 'Potentially malicious input detected' };
    }

    return Joi.validate(sanitized, schema);
  }

  // A04:2021 - Insecure Design
  static implementSecureDesign(): SecurityDesignPrinciples {
    return {
      defenseInDepth: true,
      failSecurely: true,
      leastPrivilege: true,
      separationOfDuties: true,
      economyOfMechanism: true,
      completeMediation: true,
      openDesign: true,
      psychologicalAcceptability: true
    };
  }
}
```

### OWASP ASVS Implementation

```typescript
// Application Security Verification Standard
class ASVSCompliantValidator {
  // V1: Architecture, Design and Threat Modeling
  static validateArchitecturalSecurity(application: Application): ASVSResult {
    const checks = [
      this.verifyThreatModel(application),
      this.verifySecureArchitecture(application),
      this.verifySecurityRequirements(application)
    ];
    
    return this.aggregateResults(checks, 'V1_ARCHITECTURE');
  }

  // V2: Authentication
  static validateAuthentication(authSystem: AuthenticationSystem): ASVSResult {
    return {
      passwordPolicy: this.verifyPasswordPolicy(authSystem.passwordPolicy),
      mfaImplementation: this.verifyMFA(authSystem.mfaConfig),
      sessionManagement: this.verifySessionSecurity(authSystem.sessionConfig),
      accountLockout: this.verifyAccountLockout(authSystem.lockoutPolicy)
    };
  }

  // V3: Session Management
  static validateSessionManagement(sessionConfig: SessionConfig): ASVSResult {
    const sessionSecurityChecks = {
      sessionIdGeneration: this.verifySecureRandomGeneration(sessionConfig.idGenerator),
      sessionTimeout: this.verifySessionTimeout(sessionConfig.timeout),
      sessionInvalidation: this.verifyProperInvalidation(sessionConfig.invalidation),
      cookieSecurity: this.verifySecureCookies(sessionConfig.cookies)
    };

    return this.evaluateSecurityLevel(sessionSecurityChecks);
  }

  private static verifySecureCookies(cookieConfig: CookieConfig): boolean {
    return cookieConfig.secure && 
           cookieConfig.httpOnly && 
           cookieConfig.sameSite === 'Strict' &&
           cookieConfig.path === '/' &&
           cookieConfig.expires !== undefined;
  }
}
```

## PCI DSS Compliance

### Payment Card Industry Data Security Standard

```typescript
// PCI DSS Requirement Implementation
class PCIDSSCompliance {
  // Requirement 1: Firewall Configuration
  static configureFirewall(): FirewallConfig {
    return {
      defaultDenyAll: true,
      allowedPorts: [80, 443, 22], // Minimal required ports
      networkSegmentation: true,
      dmzConfiguration: {
        webServers: 'dmz-web',
        applicationServers: 'internal-app',
        databaseServers: 'internal-db'
      },
      logging: {
        enabled: true,
        level: 'detailed',
        retention: '1year'
      }
    };
  }

  // Requirement 2: Default Password Changes
  static enforceSecureDefaults(): SecurityPolicy {
    return {
      changeDefaultPasswords: true,
      removeUnnecessaryServices: true,
      configureSystemComponents: {
        webServers: this.hardenWebServer(),
        databases: this.hardenDatabase(),
        operatingSystems: this.hardenOS()
      }
    };
  }

  // Requirement 3: Protect Stored Cardholder Data
  static protectCardholderData(cardData: CardholderData): EncryptedData {
    // Encrypt with AES-256
    const encryptedPAN = this.encryptPAN(cardData.primaryAccountNumber);
    
    // Mask PAN for display
    const maskedPAN = this.maskPAN(cardData.primaryAccountNumber);
    
    // Hash sensitive authentication data
    const hashedData = this.hashSensitiveData(cardData.sensitiveAuthData);

    return {
      encryptedPAN,
      maskedPAN,
      hashedData,
      encryptionMethod: 'AES-256-GCM',
      keyManagement: this.getKeyManagementInfo()
    };
  }

  // Requirement 4: Encrypt Transmission
  static secureTransmission(): TransmissionSecurity {
    return {
      tlsVersion: 'TLS 1.3',
      strongCryptography: true,
      properCertificateValidation: true,
      endToEndEncryption: true,
      protocols: {
        https: { enabled: true, version: 'TLS 1.3' },
        ssh: { enabled: true, version: 'SSH-2' },
        sftp: { enabled: true },
        disabledProtocols: ['SSL', 'TLS 1.0', 'TLS 1.1', 'WEP']
      }
    };
  }

  private static encryptPAN(pan: string): string {
    const key = this.getEncryptionKey();
    const iv = crypto.randomBytes(16);
    const cipher = crypto.createCipher('aes-256-gcm', key, iv);
    
    let encrypted = cipher.update(pan, 'utf8', 'hex');
    encrypted += cipher.final('hex');
    
    return `${iv.toString('hex')}:${encrypted}`;
  }
}
```

## SOC 2 Compliance Framework

### Service Organization Control 2

```typescript
// SOC 2 Trust Services Criteria Implementation
class SOC2Compliance {
  // Security (Common Criteria)
  static implementSecurityControls(): SecurityControls {
    return {
      accessControls: {
        logicalAccess: this.implementLogicalAccess(),
        physicalAccess: this.implementPhysicalAccess(),
        privilegedAccess: this.implementPrivilegedAccess()
      },
      systemOperations: {
        jobScheduling: this.implementJobScheduling(),
        backupRestore: this.implementBackupRestore(),
        systemMonitoring: this.implementSystemMonitoring()
      },
      changeManagement: {
        softwareAcquisition: this.implementSoftwareAcquisition(),
        programChanges: this.implementProgramChanges(),
        infrastructureChanges: this.implementInfrastructureChanges()
      }
    };
  }

  // Availability
  static implementAvailabilityControls(): AvailabilityControls {
    return {
      performanceMonitoring: {
        systemCapacity: this.monitorSystemCapacity(),
        performanceIndicators: this.trackPerformanceIndicators(),
        dataProcessing: this.monitorDataProcessing()
      },
      onlineBackup: {
        dataBackup: this.implementDataBackup(),
        systemBackup: this.implementSystemBackup(),
        disasterRecovery: this.implementDisasterRecovery()
      },
      recoveryTesting: {
        backupTesting: this.testBackupRecovery(),
        failoverTesting: this.testFailoverProcedures(),
        recoveryProcedures: this.testRecoveryProcedures()
      }
    };
  }

  // Processing Integrity
  static implementProcessingIntegrityControls(): ProcessingIntegrityControls {
    return {
      dataInputControls: {
        dataValidation: this.implementDataValidation(),
        completenessChecks: this.implementCompletenessChecks(),
        accuracyControls: this.implementAccuracyControls()
      },
      dataProcessingControls: {
        processMonitoring: this.implementProcessMonitoring(),
        errorHandling: this.implementErrorHandling(),
        dataIntegrity: this.implementDataIntegrity()
      },
      dataOutputControls: {
        outputValidation: this.implementOutputValidation(),
        reportingControls: this.implementReportingControls(),
        dataTransmission: this.implementSecureDataTransmission()
      }
    };
  }

  private static implementDataValidation(): DataValidationConfig {
    return {
      inputValidation: {
        syntaxValidation: true,
        semanticValidation: true,
        businessRuleValidation: true,
        crossFieldValidation: true
      },
      validationRules: [
        { field: 'email', pattern: '^[^@]+@[^@]+\\.[^@]+$' },
        { field: 'phone', pattern: '^\\+?[1-9]\\d{1,14}$' },
        { field: 'ssn', pattern: '^\\d{3}-\\d{2}-\\d{4}$' }
      ],
      errorHandling: {
        logValidationErrors: true,
        rejectInvalidData: true,
        notifyDataOwners: true
      }
    };
  }
}
```

## HIPAA Security Framework

### Healthcare Information Security

```typescript
// HIPAA Security Rule Implementation
class HIPAASecurityFramework {
  // Administrative Safeguards
  static implementAdministrativeSafeguards(): AdministrativeSafeguards {
    return {
      securityOfficer: {
        designated: true,
        responsibilities: [
          'Develop security policies',
          'Conduct security training',
          'Manage access controls',
          'Incident response coordination'
        ]
      },
      workforceTraining: {
        securityAwareness: this.implementSecurityTraining(),
        accessManagement: this.implementAccessTraining(),
        incidentReporting: this.implementIncidentTraining()
      },
      accessManagement: {
        userProvisioning: this.implementUserProvisioning(),
        accessReview: this.implementAccessReview(),
        terminationProcedures: this.implementTerminationProcedures()
      }
    };
  }

  // Physical Safeguards
  static implementPhysicalSafeguards(): PhysicalSafeguards {
    return {
      facilityAccess: {
        physicalAccessControls: true,
        biometricAccess: true,
        visitorManagement: true,
        securityCameras: true
      },
      workstationSecurity: {
        screenLocks: true,
        physicalSecurity: true,
        cleanDesk: true,
        deviceEncryption: true
      },
      deviceControls: {
        inventoryManagement: true,
        mediaControls: true,
        disposalProcedures: true,
        dataWiping: true
      }
    };
  }

  // Technical Safeguards
  static implementTechnicalSafeguards(): TechnicalSafeguards {
    return {
      accessControl: {
        uniqueUserIdentification: true,
        automaticLogoff: this.configureAutomaticLogoff(),
        encryptionDecryption: this.configureEncryption(),
        roleBasedAccess: this.configureRBAC()
      },
      auditControls: {
        auditLogs: this.configureAuditLogging(),
        logProtection: this.configureLogProtection(),
        reviewProcedures: this.configureLogReview()
      },
      integrity: {
        dataIntegrity: this.configureDataIntegrity(),
        transmissionSecurity: this.configureTransmissionSecurity(),
        authenticationControls: this.configureAuthentication()
      }
    };
  }

  private static configureAuditLogging(): AuditConfig {
    return {
      logEvents: [
        'PHI_ACCESS',
        'PHI_MODIFICATION',
        'PHI_DELETION',
        'USER_LOGIN',
        'USER_LOGOUT',
        'SYSTEM_ACCESS',
        'CONFIGURATION_CHANGES'
      ],
      logFormat: {
        timestamp: 'ISO8601',
        userId: 'required',
        action: 'required',
        resource: 'required',
        outcome: 'required',
        reasonCode: 'optional'
      },
      retention: '6years',
      protection: {
        encrypted: true,
        tamperProof: true,
        accessControlled: true
      }
    };
  }
}
```

## GDPR Compliance Framework

### General Data Protection Regulation

```typescript
// GDPR Compliance Implementation
class GDPRCompliance {
  // Article 25: Data Protection by Design and by Default
  static implementDataProtectionByDesign(): DataProtectionConfig {
    return {
      privacyByDesign: {
        dataMinimization: this.implementDataMinimization(),
        purposeLimitation: this.implementPurposeLimitation(),
        storageMinimization: this.implementStorageMinimization()
      },
      privacyByDefault: {
        defaultPrivacySettings: true,
        optInConsent: true,
        granularControls: true,
        transparentProcessing: true
      },
      technicalMeasures: {
        pseudonymization: this.implementPseudonymization(),
        encryption: this.implementGDPREncryption(),
        accessControls: this.implementGDPRAccessControls()
      }
    };
  }

  // Article 32: Security of Processing
  static implementSecurityOfProcessing(): SecurityMeasures {
    return {
      technicalMeasures: {
        encryption: {
          inTransit: 'TLS 1.3',
          atRest: 'AES-256-GCM',
          keyManagement: 'HSM-based'
        },
        pseudonymization: this.configurePseudonymization(),
        integrityConfidentiality: this.configureIntegrityControls()
      },
      organizationalMeasures: {
        staffTraining: this.configureGDPRTraining(),
        processingRecords: this.maintainProcessingRecords(),
        dataBreachProcedures: this.configureBreachProcedures()
      },
      resilience: {
        systemResilience: this.configureSystemResilience(),
        dataAvailability: this.configureDataAvailability(),
        businessContinuity: this.configureBCP()
      }
    };
  }

  // Data Subject Rights Implementation
  static implementDataSubjectRights(): DataSubjectRights {
    return {
      rightOfAccess: this.implementAccessRight(),
      rightOfRectification: this.implementRectificationRight(),
      rightOfErasure: this.implementErasureRight(),
      rightToDataPortability: this.implementPortabilityRight(),
      rightToObject: this.implementObjectionRight(),
      rightToRestrictProcessing: this.implementRestrictionRight()
    };
  }

  private static implementAccessRight(): AccessRightConfig {
    return {
      requestHandling: {
        maxResponseTime: '30days',
        identityVerification: 'strong',
        dataFormat: 'structured',
        deliveryMethod: 'secure'
      },
      dataProvision: {
        personalData: true,
        processingPurposes: true,
        dataCategories: true,
        recipients: true,
        retentionPeriod: true,
        dataSource: true,
        automatedDecisionMaking: true
      }
    };
  }
}
```

## Common Implementation Patterns

### Security Monitoring Dashboard

```typescript
// Unified Security Dashboard
class SecurityDashboard {
  private frameworks: SecurityFramework[] = [
    new NISTFramework(),
    new ISO27001Framework(),
    new OWASPFramework(),
    new PCIDSSFramework(),
    new SOC2Framework(),
    new HIPAAFramework(),
    new GDPRFramework()
  ];

  generateComplianceReport(): ComplianceReport {
    const frameworkReports = this.frameworks.map(framework => ({
      name: framework.name,
      version: framework.version,
      lastAssessment: framework.lastAssessmentDate,
      complianceScore: framework.calculateComplianceScore(),
      criticalIssues: framework.getCriticalIssues(),
      recommendations: framework.getRecommendations()
    }));

    return {
      generatedAt: new Date(),
      overallScore: this.calculateOverallScore(frameworkReports),
      frameworks: frameworkReports,
      executiveSummary: this.generateExecutiveSummary(frameworkReports),
      actionItems: this.prioritizeActionItems(frameworkReports)
    };
  }

  private calculateOverallScore(reports: FrameworkReport[]): number {
    const totalScore = reports.reduce((sum, report) => sum + report.complianceScore, 0);
    return Math.round(totalScore / reports.length);
  }
}
```

### Security Testing Framework

```typescript
// Automated Security Testing
class SecurityTestSuite {
  static runSecurityTests(): Promise<SecurityTestResults> {
    return Promise.all([
      this.runVulnerabilityScans(),
      this.runPenetrationTests(),
      this.runComplianceTests(),
      this.runAccessControlTests(),
      this.runEncryptionTests(),
      this.runNetworkSecurityTests()
    ]).then(results => this.aggregateResults(results));
  }

  private static async runComplianceTests(): Promise<ComplianceTestResults> {
    const tests = [
      () => NISTFramework.runComplianceTests(),
      () => ISO27001Framework.runComplianceTests(),
      () => OWASPFramework.runSecurityTests(),
      () => PCIDSSFramework.runComplianceTests(),
      () => SOC2Framework.runControlTests(),
      () => HIPAAFramework.runSafeguardTests(),
      () => GDPRFramework.runPrivacyTests()
    ];

    const results = await Promise.allSettled(tests.map(test => test()));
    
    return {
      passedTests: results.filter(r => r.status === 'fulfilled').length,
      failedTests: results.filter(r => r.status === 'rejected').length,
      totalTests: results.length,
      compliancePercentage: (results.filter(r => r.status === 'fulfilled').length / results.length) * 100,
      detailedResults: results
    };
  }
}
```

## Best Practices Summary

### Implementation Checklist

- [ ] **Multi-Framework Approach**: Implement multiple frameworks simultaneously for comprehensive coverage
- [ ] **Risk-Based Implementation**: Prioritize controls based on risk assessment results
- [ ] **Continuous Monitoring**: Implement automated compliance monitoring and reporting
- [ ] **Regular Assessments**: Conduct quarterly security assessments and annual framework reviews
- [ ] **Staff Training**: Provide regular security awareness training aligned with framework requirements
- [ ] **Documentation**: Maintain comprehensive documentation of all security controls and procedures
- [ ] **Incident Response**: Implement robust incident response procedures meeting all framework requirements
- [ ] **Third-Party Risk**: Assess and monitor third-party vendors for compliance with security frameworks
- [ ] **Metrics and KPIs**: Define and track security metrics aligned with framework objectives
- [ ] **Executive Reporting**: Provide regular compliance reports to executive leadership and board

### Common Pitfalls to Avoid

1. **Framework Silos**: Don't implement frameworks in isolation; ensure they work together cohesively
2. **Checkbox Compliance**: Focus on actual security improvement, not just meeting requirements
3. **Inadequate Testing**: Regularly test and validate security controls effectiveness
4. **Poor Change Management**: Ensure security controls are updated when systems change
5. **Insufficient Training**: Provide adequate training to all staff on security requirements
6. **Weak Monitoring**: Implement robust monitoring to detect control failures quickly
7. **Documentation Gaps**: Maintain current and comprehensive documentation of all controls

This comprehensive approach ensures battle-tested, government-grade security that meets the highest industry standards while providing practical implementation guidance for development teams.