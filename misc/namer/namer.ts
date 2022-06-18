
function sample<T = any>(arr: T[]){
    return arr[Math.floor(Math.random() * arr.length)];
}

function cleanse(str: string) {
    return str.replace(/[^a-z]/g, "").toLowerCase();
}

function makeIt(...arrs: string[][]) {
    return arrs.map(sample).map(cleanse).join("-");
}

void async function () {
    const __dirname = new URL('.', import.meta.url).pathname;
    const adjectives = (await Deno.readTextFile(__dirname + "adjectives.txt")).split("\n");
    const colors = (await Deno.readTextFile(__dirname + "colors.txt")).split("\n");
    const nouns = (await Deno.readTextFile(__dirname + "nouns.txt")).split("\n");
    
    const result = sample([
        makeIt(adjectives, colors, nouns),
        makeIt(adjectives, nouns),
        makeIt(adjectives, nouns),
        makeIt(adjectives, nouns),
        makeIt(colors, nouns),
        makeIt(colors, nouns),
    ]);

    console.log(result);
}()
