/* 

    filename: master.js
    author: WazowskiTheUgly 9/14/2024

    description: Essentially its just a CLI that incorporates some useful commands to make changes using
    the roblox web API. Saves time compared to doing this stuff on the actual roblox website

    script: npm run jsc 

*/

// Imports:

const noblox = require('noblox.js');
const readline = require(`node:readline`);

// Configure dotenv & Authenticate roblox cookie:

const dotenv = require('dotenv');
const {stdin : input, stdout : output} = require(`node:process`);

async function initialize_cookie() {
    await noblox.setCookie(process.env.__COOKIE);
}

dotenv.config();
initialize_cookie();

// Configure available commands & Readline interface.

var question = `>> Select the command you would like to use. \n`

const interface = readline.createInterface({input, output});
const commands = {
    
    'addProduct': 'Creates a new developer product',
    'bulkUploadImages': 'Upload multiple images to roblox at once.'

}

// @function generateQuestion: Lists out all available commands.

function generateQuestion() {

    for (const [ command, _ ] of Object.entries(commands)) {

        const str = `\n   >> ${command}`
        question += str

    }

    return question + ` \n \n   `
}

// @function GenerateFollowUpQuestion: Blocks code until an answer has been given.

function GenerateFollowUpQuestion(question) {
    return new Promise(resolve => {
        interface.question(question, (answer) => { resolve(answer) })
    })
}

// Make a divider

function Divider() {
    console.log(`   --------------------------------------- `)
}

interface.question(generateQuestion(), (answer) => {
    if (commands[answer]) {

        // Import corresponding mobile:

        var args = {}

        const command = answer
        const module = require(`./${command}`)

        Divider()

        // Ask for all answers in order
        
        async function Execute() {
            for (const question of module.arguments) {
                
                const answer = await GenerateFollowUpQuestion(`>> ${question}:  `)
                args[question] = answer;

            };
            
            Divider()
            module.callback_function(interface, args)

        }

        Execute();

    } 
    
    // Invalid command, close the interface:

    else {

        console.log("   >>> Command is not valid!")
        interface.close()

    }
})
