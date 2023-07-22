import JSZip from 'jszip'
import { readFileSync, readdirSync, lstatSync } from 'node:fs'
import {
    LambdaClient,
    PublishLayerVersionCommand,
} from '@aws-sdk/client-lambda'
import 'dotenv/config'

const regions = [
    'us-east-1',
    'us-east-2',
    'us-west-1',
    'us-west-2',
    'af-south-1',
    'ap-east-1',
    'ap-south-2',
    'ap-southeast-3',
    'ap-south-1',
    'ap-northeast-3',
    'ap-northeast-2',
    'ap-southeast-1',
    'ap-southeast-2',
    'ap-northeast-1',
    'ca-central-1',
    'eu-central-1',
    'eu-west-1',
    'eu-west-2',
    'eu-south-1',
    'eu-west-3',
    'eu-south-2',
    'eu-north-1',
    'eu-central-2',
    'me-south-1',
    'me-central-1',
    'sa-east-1',
]

function ZipFolder(path, jszip) {
    for (const name of readdirSync(path)) {
        const stat = lstatSync(`${path}/${name}`)
        const isDir = stat.isDirectory()
        const isFile = stat.isFile()

        if (isDir) {
            const zip = jszip.folder(name)

            ZipFolder(`${path}/${name}`, zip)
        }

        if (isFile) {
            jszip.file(
                name,
                readFileSync('./bootstrap', {
                    encoding: 'utf-8',
                })
            )
        }
    }
}

function ZipRuntime() {
    const zip = new JSZip()

    const boostrap = readFileSync('./bootstrap', {
        encoding: 'utf-8',
    })
    zip.file('bootstrap', boostrap)

    const runtimeFolder = zip.folder('runtime')

    ZipFolder('./runtime', runtimeFolder)

    return zip.generateAsync({
        type: 'uint8array',
    })
}

async function main() {
    const zipped = await ZipRuntime()

    for (const region of regions) {
        const client = new LambdaClient({ region })

        const publishCommand = new PublishLayerVersionCommand({
            LayerName: 'Luambda',
            Content: {
                ZipFile: zipped,
            },
        })

        await client.send(publishCommand)
        console.log(region, ': DONE')
    }
}

main()
