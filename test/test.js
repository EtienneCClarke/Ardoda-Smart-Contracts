
const Factory = artifacts.require('MPAFactory.sol');
const MPA = artifacts.require('MPA.sol');

contract('MPAFactory', () => {

    it('Creates new MPA', async () => {

        // Setup
        console.log("");
        var accounts = await web3.eth.getAccounts();
        const Fac = await Factory.new({ from: accounts[9] });

        // Test

        await Fac.create(
            "Test",
            "This contract is to be locked",
            [accounts[1], accounts[2]],
            [50,50],
            true,
            { from: accounts[0] }
        );
        const ownedMPAs = await Fac.getOwnedMPAs(accounts[0]);
        const mpa = await MPA.at(ownedMPAs[0]);

        console.log("Sending Eth to MPA...")
        await web3.eth.sendTransaction({
            from: accounts[0],
            to: mpa.address,
            value: web3.utils.toWei('1', 'ether')
        });

        await balanceOf("MPA", mpa.address);
        
        await mpa.freeze(true, { from: accounts[9] })

        try {
            console.log("Sending Eth to MPA...")
            await web3.eth.sendTransaction({
                from: accounts[0],
                to: mpa.address,
                value: web3.utils.toWei('1', 'ether')
            });
        } catch (e) {
            console.log("Error: Failed to send eth!")
        }

        await mpa.freeze(false, { from: accounts[9] })

        try {
            console.log("Sending Eth to MPA...")
            await web3.eth.sendTransaction({
                from: accounts[0],
                to: mpa.address,
                value: web3.utils.toWei('1', 'ether')
            });
        } catch (e) {
            console.log("Error: Failed to send eth!")
        }

        await balanceOf("MPA", mpa.address);

        console.log("");

    });
 
});

// Util Functions

async function balanceOf(tag, address) {
    const bal = await web3.eth.getBalance(address);
    console.log(`  => Balance of ${tag}: ${address} is ${bal} Wei`);
    return bal;
}

function toEth(amount) {
    return web3.utils.fromWei(amount, "ether");
}