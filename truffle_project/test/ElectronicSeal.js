const ElectronicSeal = artifacts.require('ElectronicSeal');


contract('ElectronicSeal', function (accounts){
    let electronicSeal;

    before(async function (){
        electronicSeal = await ElectronicSeal.new();
    });

    it('addSealAccount', async () =>{
    })

    it('getSealAccount', async () => {      

    })

    it('getSealAccountCounter', async () => {      

    })

    it('cancelSealAccount', async () => {      

    })

    it('sealSignature', async () => {      

    })

    it('querySignature', async () => {      

    })
})