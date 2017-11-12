## Disclaimer

This is an abstract of Microsoft's DevOps basics [course](https://openedx.microsoft.com/courses/course-v1:Microsoft+DevOps200.1+2017_T2/info)

## Intro
Main DevOps idea - fast release cycles.

![John Allspaw's visual of delivery cycles](/files/devops/001_John_Allspaw_s_from_slow_to_fast_delivery.png)

Fast release cycles - savings.

![Potential savings. Shifting left](/files/devops/002_shifting_left.png)

### Seven Key DevOps Practices:
* Configuration Management
* Release Management
* Continuous Integration
* Continuous Deployment
* Infrastructure as Code
* Test Automation
* Application Performance Monitoring

## Compliance and Security
Main idea: compliance and security requirements should be saved as a code and tested the same.

### Compliance
Azure offer secrets management solutions like [Key Vault](https://azure.microsoft.com/en-us/services/key-vault/), which gives ability to abstract sensitive information from all users.
With fast feedback loops, if there are noncompliance issues, corrections can be made quickly, and the changes can be tracked automatically.
Compliance requirements can be stored as code, allowing it to be tested just like any other piece of solution in the software development pipeline

### Security
1. Component packages can be automatically scanned from a trusted registry
2. Security can be addressed when development begins with code analysis - failures can break the build
3. If a vulnerability is discovered - automated pipeline allow fast fix deployment.
4. Possibility to automate simulated attacks and stress on the system

## Configuration Management
* **Infrastructure as Code**: defining environments, as a text file (script or definition) that is checked into version control and used as the base source for creating or updating those environments.
* **Configuration as Code**: defining the configuration of your servers, code, and other resources as a text file (script or definition) that is checked into version control and used as the base source for creating or updating those configurations.

Benefits: More maintainable, fewer locations to update, fewer mistakes, more secure, more reliable, consistent servers between environments, bugs easily reproducible, increase speed of new environment setup or change.

> A common analogy of using **Infrastructure as Code** is the idea of owning cattle, not pets

![Cattle vs. Pets](/files/devops/003_servers_pets_or_cattle.jpg)

## Azure Resource Manager (ARM) and Desired State Configuration (DSC)
### ARM
A [resource group](https://docs.microsoft.com/en-us/azure/azure-resource-manager/resource-group-overview#resource-groups) is a container that holds related resources for an application. The resource group could include all of the resources for an application, or only those resources that are logically grouped together.

Why use ARM:
* You can deploy, manage, and monitor all of the resources for your solution as a group, known as a resource group, rather than handle these resources individually.
* You can repeatedly deploy your solution throughout the development lifecycle and have confidence your resources are deployed in a consistent state.
* You can use declarative templates to define your deployment.
* You can define the dependencies between resources so they are deployed in the correct order.
* You can apply access control to all services in your resource group because Role-Based Access Control (RBAC) is natively integrated into the management platform.
* You can apply tags to resources to logically organize all of the resources in your subscription.
* You can clarify billing for your organization by viewing the rolled-up costs for the entire group or for a group of resources sharing the same tag.

ARM template structure:

```json
{ 
"$schema": "http://schema.management.azure.com/schemas/2015-01-01/deploymentTemplate.json#",
"contentVersion": "",
"parameters": {  },
"variables": {  },
"resources": [  ],
"outputs": {  }
}
```

There is huge GitHub repository, which contains all currently available [Azure Resource Manager templates](https://github.com/Azure/azure-quickstart-templates) contributed by the community.

### DSC
DSC lets you manage, deploy, and enforce configurations for physical or virtual machines.

![DSC](/files/devops/004_dsc.png)

1. Create a PowerShell script with the configuration element.
2. Upload the script to Azure Automation and compile the script into a Managed Object Format (MOF) file. The file is transferred to the DSC pull server.
3. Define the nodes that will use the configuration.

There is [Azure Automation DSC](https://docs.microsoft.com/en-us/azure/automation/automation-dsc-overview), which allows automate this process and easily monitor configured VMs.

## Continuous Integration (CI) and Continuous Deployment (CD)
### CI 
Automated builds are valuable because they:
* validate that code compilation doesn’t just succeed “on my machine.”
* run as many tasks as needed, such as scripting, testing, packaging, or anything else required.
* publish artifacts to be picked up for deployment.
* maintain audit history for build details, drop details, and associated work items.

Continuous Integration (CI) provides benefits:
* improving code quality based on rapid feedback.
* triggering for automated testing for every code change.
* better managing technical debt and conducting code analysis.
* reducing long, difficult and bug-inducing merges.
* increasing confidence in code long before production.

### CD
By implementing automated deployments, you can: 
* deploy to multiple environments either in parallel or one at a time, 
* set manual approvals to certain environments, 
* re-deploy to environments, and perform configuration transforms between environments
* decrease release cadence
* get fast feedback cycles

![CI-CD](/files/devops/005_cicd.png)

![CI-CD Pipeline](/files/devops/006_cicd_pipeline.png)

### Practice
1. [Continuous Integration with Visual Studio Team Services](https://github.com/Microsoft/PartsUnlimited/tree/master/docs/HOL-Continuous_Integration)
2. [Continuous Deployment with Release Management in Visual Studio Team Services](https://github.com/Microsoft/PartsUnlimited/tree/master/docs/HOL-Continuous_Deployment)

## Testing
Automated testing helps developers run tests early and often to ensure they are testing their software quality continuously and make decisions whether to release their product or not.
* early and timely feedback
* speeds up software delivery
* reduces cost
* reliability
* repeatability

Consider the software development lifecycle as a sequence of events that start on the left and end on the right.

#### Shifting Right
In some processes, important actions such as testing and security are inadvertently saved until later in a release (or iteration), called “shifting right.” That delay causes adverse consequences, such as finding bugs too late from testing or discovering security holes in applications.

#### Shifting Left
Designing, monitoring, and identifying problems, and fixing bugs and vulnerabilities earlier. This concept is called “shifting left.” Fewer issues will be found in production because tests reveal and resolve the issues earlier.

### Types of Tests 
#### Unit tests
* Typically developed and run by developers at the start/during the software development process.
* Run at every build to test individual units of system in isolation

#### Integration tests
Run at every build to see how different software modules/components are coming together and identifies any integration issues early.

#### Automated UI tests
* Run once the application UI is up and running to test the functionalities of the application ensuring various components of the application work as expected.
* These tests let you validate whether the whole application (including its User Interface) is working correctly.
* Many times, they are used to automate an existing manual test.

#### Performance Tests and Load Tests
* Must be run before release to the production to ensure application can perform per end user expectations and handle expected levels of load.
* Tests whether a system can perform under heavy user load to meet non-functional requirements, such as response time of a web page.

#### Manual Acceptance and Exploratory Tests
* Typically run manually before production to ensure the software meets the business requirements/needs.
* In this type of test, a tester is responsible to manage her or his own time and find creative ways to test the system at any stage.

#### Beta testing
A form of external user acceptance testing where beta versions of an application are released to a limited audience, known as beta testers. Versions are released to groups of people for more testing, and sometimes made available to the public for more feedback.

### Practice
[Testing in Production with Azure Websites](https://github.com/Microsoft/PartsUnlimited/tree/master/docs/HOL-HDD_Testing_in_Production)

## Continuous learning from production
### Application Performance Monitoring (APM)
APM tools usually provide the following information:
* Diagnostics and error reporting
* Usage patterns and trends
* Notifications on application performance

[Application Insights overview](https://docs.microsoft.com/en-us/azure/application-insights/app-insights-overview)

### Progressive exposure 
Switching small numbers of users over to a new version of software for feedback, then progressively exposing more users to the features over time.

### Feature Flags
A feature flag is a conditional in your code *an if then* which flags a new or risky behavior.  First, the feature is deployed “off”. Then, separate from deployment, you can turn on the new feature. If the feature doesn’t behave as expected, it is possible to shut it off quickly.

### Blue-Green Deployments
Blue-green deployments are based on two identical production environments. The key is to ensure that the two environments are truly identical, including the data they manage. Zero downtime releases are achieved by deploying to the "blue" environment. After the new deployment is smoke tested, traffic is routed to the "green" environment, which now becomes the production environment.

Note, this process works for code, only. The database is typically a single environment because having two matching databases, where the replica of the active one changes every time you switch, requires a complicated setup

### Canary Releasing
Similar to blue-green deployments, canary releasing addresses the challenge of testing a new release with only a subset of servers: a small percentage of users are routed to the new service, while the majority still works against the old version. 

When the team is confident that the new service is working properly, they can begin to release it to more and more servers and routing more users to it. Once all users have migrated to the new version, you can decommission the old version. If, after decommissioning the old version, problems arise with the new version, the strategy is to once again route users to the old version.
For more information on canary releases, see Martin Fowler's [blog](http://martinfowler.com/bliki/CanaryRelease.html).

### Hypothesis-Driven Development
Create hypothesis - make experiment - measure result.
It's encourage experimentations, innovations.

### Practice
[User Telemetry and Performance Monitoring with Application Insights](https://github.com/Microsoft/PartsUnlimited/tree/master/docs/HOL_User_Telemetry_APM_With_App_Insights)