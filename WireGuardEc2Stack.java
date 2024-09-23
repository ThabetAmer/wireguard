import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Paths;
import java.util.Arrays;

import software.amazon.awscdk.CfnOutput;
import software.amazon.awscdk.CfnOutputProps;
import software.amazon.awscdk.RemovalPolicy;
import software.amazon.awscdk.StackProps;
import software.amazon.awscdk.services.ec2.*;
import software.amazon.awscdk.services.iam.*;
import software.amazon.awscdk.services.s3.Bucket;
import software.amazon.awscdk.services.s3.BucketEncryption;
import software.amazon.awscdk.services.s3.ObjectOwnership;

import software.constructs.Construct;

public class WireGuardEc2Stack extends stack {

        // Declare variables here
        private final String bastionWireguardBucketName = "your-s3-bucket-name";
        private final String bastionWireguardKeyPairName = "your-key-pair-name";
        
        private final String ec2InstanceType = "BURSTABLE2";
        private final String ec2InstanceSize = "SMALL";


        public WireGuardEc2Stack(final Construct scope, final String id) {
                this(scope, id, null);
        }
      
        public WireGuardEc2Stack(final Construct scope, final String id, final StackProps props) {
                super(scope, id, props);

                // Lookup default VPC and its subnets
                IVpc myVPC = Vpc.fromLookup(this, "myVPC", VpcLookupOptions.builder().isDefault(true).build());
                ISubnet bastionHostSubnet = myVPC.getPublicSubnets().get(0);

                // Create s3 bucket for storing vpn configs outside of ec2
                Bucket.Builder.create(this, "bastionWireguardBucket")
                        .bucketName(bastionWireguardBucketName)
                        .publicReadAccess(false)
                        .objectOwnership(ObjectOwnership.BUCKET_OWNER_ENFORCED)
                        .removalPolicy(RemovalPolicy.RETAIN_ON_UPDATE_OR_DELETE)
                        .encryption(BucketEncryption.S3_MANAGED)
                        .bucketKeyEnabled(false)
                        .versioned(true)
                        .build();
        
                // Create a security group that allows incoming traffic on the WireGuard port (51820/UDP)
                SecurityGroup securityGroup = SecurityGroup.Builder.create(this, "bastionWireguardSG")
                        .vpc(myVPC)
                        .allowAllOutbound(true)
                        .securityGroupName("bastionWireguardSG")
                        .description("BX Bastion security group")
                        .build();

                securityGroup.addIngressRule(Peer.anyIpv4(), Port.udp(51820), "Allow WireGuard traffic");

                // Define the policy statement
                PolicyStatement s3PolicyStatement = PolicyStatement.Builder.create()
                        .effect(Effect.ALLOW)
                        .actions(Arrays.asList(
                                "s3:DeleteObject",
                                "s3:ListMultipartUploadParts",
                                "s3:PutObject",
                                "s3:GetObject",
                                "s3:DeleteObjectVersion",
                                "s3:ListBucketVersions",
                                "s3:RestoreObject",
                                "s3:ListBucket",
                                "s3:GetBucketPolicy",
                                "s3:AbortMultipartUpload",
                                "s3:ListBucketMultipartUploads"
                        ))
                        .resources(Arrays.asList(
                                "arn:aws:s3:::"+bastionWireguardBucketName,
                                "arn:aws:s3:::"+bastionWireguardBucketName+"/wireguard/*"
                        ))
                        .build();

                // Load user data from a file
                String userDataContent = "";
                try {
                        userDataContent = new String(Files.readAllBytes(Paths.get("userdata-bastion-wireguard.sh")));
                } catch (IOException e) {
                        e.printStackTrace();
                }

                // Create the Bastion Host
                BastionHostLinux bastionHost = new BastionHostLinux(this, "bastionWireguardHost",
                        BastionHostLinuxProps.builder()
                                .vpc(myVPC)
                                .instanceName("bastionWireguardHost")
                                .instanceType(InstanceType.of(InstanceClass.valueOf(ec2InstanceType), InstanceSize.valueOf(ec2InstanceSize)))
                                .machineImage(
                                new AmazonLinuxImage(AmazonLinuxImageProps.builder()
                                        .generation(AmazonLinuxGeneration.AMAZON_LINUX_2)
                                        .build()))
                                .subnetSelection(
                                        SubnetSelection.builder()
                                                .subnets(Arrays.asList(bastionHostSubnet))
                                                .build())
                                .securityGroup(securityGroup)
                                .build());


                // User data script to install and configure WireGuard
                bastionHost.getInstance().addUserData(userDataContent);

                // Access to the s3 configs
                bastionHost.getInstance().addToRolePolicy(s3PolicyStatement);

                // attach key for ssh
                bastionHost.getInstance().getInstance().addPropertyOverride("KeyName", bastionWireguardKeyPairName);

                // Create an Elastic IP
                CfnEIP eip = CfnEIP.Builder.create(this, "Eip")
                        .domain("vpc")
                        .build();

                // Associate the Elastic IP with the Bastion Host using allocationId
                CfnEIPAssociation.Builder.create(this, "EipAssociation")
                        .allocationId(eip.getAttrAllocationId())
                        .instanceId(bastionHost.getInstance().getInstanceId())
                        .build();


                // outputs for secuirty group ID and IP address
                new CfnOutput(this, "bastionWireguardHostSGIdOutput", CfnOutputProps.builder()
                        .value(securityGroup.getSecurityGroupId())
                        .exportName("bastionWireguard-securityGroup-id")
                        .build());
                new CfnOutput(this, "bastionWireguardHostIPOutput", CfnOutputProps.builder()
                        .value(bastionHost.getInstance().getInstancePublicIp())
                        .exportName("bastionWireguard-host-ip")
                        .build());
        }
}