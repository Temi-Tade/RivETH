function COPY_ADDRESS(btn) {
    navigator.clipboard.writeText(btn.previousElementSibling.value)
    .then(() => {
        btn.style.display = "none";
        btn.nextElementSibling.style.display = "block"
        setTimeout(() => {
            btn.style.display = "block";
            btn.nextElementSibling.style.display = "none"
        }, 2000);
    })
}

function CREATE_MODAL(content) {
    // todo - animate
    document.querySelector("#modalbg").style.display = "block";
    document.querySelector("#modal p").innerHTML = content;

    document.querySelector("#modal button").onclick = function() {
        document.querySelector("#modalbg").style.display = "none";
    }

    window.onclick = function (e) {
        if (e.target === document.querySelector("#modalbg")) {
            document.querySelector("#modalbg").style.display = "none";
        }
    }
}

function DONATE() {
    CREATE_MODAL(`
        <div id="donate">
            <h4>Thank you for supporting RivETH, together, we can build a community of web3 enthusiasts who are serious about security and growth!</h4>
            <p>Donations can be sent to: 0x49Df3350fafa751212cCa8AB631cEa6e6ACB2ce6 (ERC20)</p>
        </div>
    `);
}