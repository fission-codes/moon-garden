// @ts-ignore
import { Elm } from './Viewer.elm'
import * as dataRoot from 'webnative/data-root'
import { getLinks } from "webnative/fs/protocol/basic"
import PublicTree from "webnative/fs/v1/PublicTree"

const elmApp = Elm.Viewer.init({
    flags: {}
})

elmApp.ports.loadNotesFor.subscribe(async ({ username }: { username: string }) => {
    try {
        const path = ["Documents", "Notes"]
        const rootCID = await dataRoot.lookup(username)
        const publicCid = (await getLinks(rootCID)).public.cid

        const publicTree = await PublicTree.fromCID(publicCid)
        const entries = await publicTree.ls(path)
        let entriesWithMetadata = {}
        for (const [key, entry] of Object.entries(entries)) {
            const entr = await publicTree.get([...path, entry.name])
            entriesWithMetadata[key] = {
                ...entry,
                // @ts-ignore
                metadata: entr.header.metadata
            }
        }
        elmApp.ports.loadedNotesFor.send({
            username,
            notes: entriesWithMetadata,
        })
    } catch (e) {
        console.error(e)
    }
})
