// @ts-ignore
import { Elm } from './Viewer.elm'
import * as dataRoot from 'webnative/data-root'
import { getLinks } from "webnative/fs/protocol/basic"
import PublicTree from "webnative/fs/v1/PublicTree"
import PublicFile from "webnative/fs/v1/PublicFile"

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
        elmApp.ports.loadedNotesForFailed.send({ message: e.message })
        console.error(e)
    }
})

elmApp.ports.loadNote.subscribe(async ({ username, noteName } : { username : string, noteName : string }) => {
    try {
        const path = ["Documents", "Notes", `${noteName}.md`]
        const rootCID = await dataRoot.lookup(username)
        if (rootCID == null) throw new Error("User not found")
        const publicCid = (await getLinks(rootCID)).public.cid

        const publicTree = await PublicTree.fromCID(publicCid)
        const noteFile = await publicTree.read(path) as PublicFile
        if (noteFile == null) throw new Error("Note note found")
        const noteData = new TextDecoder().decode(noteFile.content as Uint8Array)
        elmApp.ports.loadedNote.send({
            username,
            note: { noteName, noteData }
        })
    } catch (e) {
        elmApp.ports.loadedNoteFailed.send({ message: e.message })
        console.error(e)
    }
})
