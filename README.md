# Senior SRE Exercise

The following exercise is intended to help us evaluate your technical ability.
Expect this exercise to take 2-4 hours of your time.  When you are finisehd,
please submit documents as stated in the Results section below.

Note: No human beings can be used as a resource – feel free to scour the
internet.

## TL;DR

At the end of this exercise, you should have:
* AWS ECS Fargate service that runs tasks in private subnets
* Other AWS infrastructure provisioned to expose that service publicly
* A pull request / merge request

We will evaluate your submission by:
* Running the integration tests against your deployed application by running this command:
```
$ cd integration_tests && make test-production
```
* Reviewing the infrastructure that you provisioned and making sure that
  the tasks in the ECS service are Fargate tasks running in private
  subnets



See the `Results` section for more details.

## Prerequisites
* Git
* [awscli](https://aws.amazon.com/cli/https://aws.amazon.com/cli/https://aws.amazon.com/cli/) if you want to use ECR to store your docker image
* Ruby 2.6.3
* Python 3.7.2

The exercise may work with slightly different versions of Ruby and Python, but those are guaranteed to work with the existing code.

## Part 1 - Implement Lisa Endpoints

* Modify `app/simpsons_simulator.rb` to implement the Lisa endpoints described
  in `integration_tests/tests.py` such that the integration tests pass.

The first part of this task is to complete development work on the API. The API
is a Ruby application using the Sinatra web framework. The code for the API
lives in the app directory. Details for running the application locally are
included in the README.md file in that directory.

For now only Homer is implemented. Before we launch, we need to implement the
endpoints for Lisa as well.  Luckily, there are integration tests in the
`integration_tests` directory, that have tests for both the Homer and Lisa
endpoints. There are instructions for running these tests locally in the
README.md in that directory, against a locally running version of the API.

To be absolutely clear, don't change anything in `integration_tests/` at all.
Modify `app/` to make the existing tests pass.

## Part 2 - Deploy the API so it runs at https://simpsons.AWS_SUB_DOMAIN.jv-magic.com

Note: AWS_SUB_DOMAIN is the portion after the "+" provided in your login. For example jv-exercise+EXAMPLE@jellyvision.com. In this case the AWS_SUB_DOMAIN is "Example".

* Deploy the app on AWS ECS Fargate so that:
  * The ECS tasks run in private subnets
  * The app is publicly accessible at https://simpsons.AWS_SUB_DOMAIN.jv-magic.com
* The AWS infrastructure is defined as code, with Terraform (preferred) or
  CloudFormation or something similar

Once we've got Homer and List endpoints, we can launch! At Jellyvision, we
generally package our applications and services into Docker containers and run
them as AWS ECS Fargate services. That's what we'll do for this application.
Consider this application successfully deployed when the integration tests pass
against https://simpsons.AWS_SUB_DOMAIN.jv-magic.com (see the README.md in
`integration_tests/` for instructions on how to specify the url to run the
tests against).

Specifically, you'll need to:
* Create a Docker image that packages the application
* Docker image needs to be accessible to ECS
* Create AWS infrastructure to run the application on
* Configure an ECS service to run the application and have it take traffic on
  https://simpsons.AWS_SUB_DOMAIN.jv-magic.com

For this exercise, running the development server in the container is fine.
The most important thing is just to get something running.

## AWS Access

We will give you AWS credentials to an AWS account that is empty except for:
* A `jv-magic.com` Route53 Hosted Zone
* An AWS Certificate Manager (ACM) TLS certificate that covers `AWS_SUB_DOMAIN.jv-magic.com`

You can use these credentials to create any resources you need to deploy the
application.

Please create all of your resources in the `us-east-1` region.

## Results

When you are finished:
* Please submit a pull request that contains all of the changes and
  additions you made to the application.  This includes:
  * Any changes to the app you made to make the integration tests pass
  * Any Dockerfile's you wrote
* Have the updated application running in a container in an ECS Fargate service such that:
  * The ECS tasks run in private subnets
  * The app is publicly accessible at https://simpsons.AWS_SUB_DOMAIN.jv-magic.com

To evaluate your work, we will run the integration tests in an unmodified
version of the repo (the repo that you started with) against
https://simpsons.AWS_SUB_DOMAIN.jv-magic.com.  Specifically, we'll run:

    $ cd integration_tests && make test-production

We are looking for all of the tests to pass.

Please allow us a couple days to review results and provide feedback.
