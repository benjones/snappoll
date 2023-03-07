window.onload = () => {

    M.AutoInit();

    let previewTimer;
    let updateTime;

    let editor = document.getElementById('editor');
    let previewPane = document.getElementById('previewPane');

    function previewTimerCallback(){
        let now = new Date().getTime();
        if(now - updateTime < 0){
            //not ready to update yet
            setTimeout(previewTimerCallback, updateTime - now);
        } else {
            previewTimer = undefined;
            updateTime = undefined;


            let contents = editor.value;
            const formData = new FormData();
            formData.append("questionText", contents);
            const request = new XMLHttpRequest();
            request.open("POST", "/updateQuestion")
            request.addEventListener("load", (resp) => {
                console.log("ajax called");
                console.log(resp);
                console.log(request.response);

                previewPane.innerHTML = request.response;

            });
            request.send(formData);

        }
    }



    editor.addEventListener('input', (event) => {

        if(!previewTimer){
            previewTimer = setTimeout(previewTimerCallback, 1000);
        }
        //update the time on every keypress
        updateTime = new Date().getTime() + 1000;

    });

}
