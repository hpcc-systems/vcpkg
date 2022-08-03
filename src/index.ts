import dotenv from "dotenv"
dotenv.config();

import { Octokit, App } from "octokit";

async function main() {

    // Create a personal access token at https://github.com/settings/tokens/new?scopes=repo
    const octokit = new Octokit({ auth: process.env.GITHUB_TOKEN_II });

    // Compare: https://docs.github.com/en/rest/reference/users#get-the-authenticated-user
    const {
        data: { login },
    } = await octokit.rest.users.getAuthenticated();
    console.log("Hello, %s", login);

    let response: any = { status: 200 };
    for (let page = 20; page >= 0; --page) {
        response = await octokit.request('GET /orgs/{org}/packages', {
            org: 'hpcc-systems',
            package_type: 'nuget',
            page,
        });
        if (response.status === 200) {
            console.log(response.data.length);
            for (const pkg of response.data) {
                if (pkg.name.indexOf("apr") >= 0) {
                    console.log("Deleting:  " + pkg.name);
                    octokit.request('DELETE /orgs/{org}/packages/{package_type}/{package_name}', {
                        package_type: 'nuget',
                        package_name: pkg.name,
                        org: 'hpcc-systems',
                    }).then(response => {
                        console.log(response);
                    })
                }
            }
        }
    }
}

main();
