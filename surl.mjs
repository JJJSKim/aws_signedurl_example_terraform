import { 
	getSignedUrl 
} from "@aws-sdk/cloudfront-signer"; // ESM
import {
  SecretsManagerClient,
  GetSecretValueCommand,
} from "@aws-sdk/client-secrets-manager";



async function secret_get(secret_name){
	const client = new SecretsManagerClient({
	  region: "ap-northeast-2",
	});

	let response;

	try {
		response = await client.send(
    	new GetSecretValueCommand({
    	SecretId: secret_name,
    	VersionStage: "AWSCURRENT", // VersionStage defaults to AWSCURRENT if unspecified
    	})
	);
	} catch (error) {
		// For a list of exceptions thrown, see
		// https://docs.aws.amazon.com/secretsmanager/latest/apireference/API_GetSecretValue.html
		console.log("Get secret value error")
		throw error;
	}
	return JSON.parse(response.SecretString);

}



export const handler = async (event, context) => {
	try{
		//Get secret value : Private Key
		const secret_name = process.env.secret_manager;
		const priKey = await secret_get(secret_name);
		
		
		const targetBehavior = event.rawPath.split('/')[2];

		//Request body check
		let body = null;
		if (event.body && event.body !=="") {
			if (event.isBase64Encoded == true){
				body = JSON.parse(Buffer.from(event.body, 'base64').toString());
			}else{
				body = JSON.parse(event.body);
			}
		}
		
		//Signed URL cloudfront domain check
		let cloudfrontDistributionDomain;
		if (body !== null && body.originURL && body.originURL !== ""){
			cloudfrontDistributionDomain = body.originURL;
		}else{
			cloudfrontDistributionDomain = process.env.domain_name;
		}
		
		//Expire time check
		let Exp_time = new Date();
		if (body !== null && body.expTime && body.expTime !==""){
			Exp_time.setMinutes(Exp_time.getMinutes() + parseInt(body.expTime));
		}else{
			Exp_time.setMinutes(Exp_time.getMinutes() + parseInt(process.env.exp_time));
		}
		
		//Target object set
		const s3ObjectKey = event.pathParameters.proxy;
		
		//Variable set
		const url = `${cloudfrontDistributionDomain}/${s3ObjectKey}`;
		const pkPEM = `${priKey[targetBehavior]}`;
		const kpId = JSON.parse(process.env.key_pair_list)[targetBehavior];
		const expiration = Exp_time; // any Date constructor compatible
		
		//Generate SignedURL
		const signedUrl = getSignedUrl({
	  		url,
	  		keyPairId: kpId,
	  		dateLessThan: expiration,
	  		privateKey: pkPEM,
		});

		//Return value set
		let returnBody;
		let returnBase64;

		//Base64 Encode check
		if(body !== null && body.base64Encode && body.base64Encode == true){
			returnBody = Buffer.from(`{\"signedUrl\": \"${signedUrl}\"}`).toString('base64');
			returnBase64 = true;
		}else{
			returnBody = `{\"signedUrl\": \"${signedUrl}\"}`;
			returnBase64 = false;
		}
		
		return {
			"headers": {"content-type": "application/json"},
			"statusCode": 200,
			"isBase64Encoded": returnBase64,
			"body": returnBody
		};
			
	}catch(e){
		console.log("[ERROR] message: " + e);
	}
	

};
