window.onload = () => {

    M.AutoInit();

    let tabs = M.Tabs.getInstance(document.getElementById('tabList'));

    let previewTimer;
    let updateTime;

    let editor = document.getElementById('editor');
    let previewPane = document.getElementById('previewPane');

    editor.value = `The first line is the text of the question
Each line after that
is interpreted
as an answer choice
this is the 4th choice`;

    function updateQuestionPreview(startPolling){
        previewTimer = undefined;
        updateTime = undefined;

        let contents = editor.value;
        const formData = new FormData();
        formData.append("questionText", contents);
        if(startPolling){
            formData.append("startPolling", true);
        }
        const request = new XMLHttpRequest();
        request.open("POST", "/updateQuestion")
        request.addEventListener("load", (resp) => {
            if(startPolling){
                tabs.select('pollResults');
                pollResults.innerHTML = request.response;
            } else {
                previewPane.innerHTML = request.response;

            }

        });
        request.send(formData);
    }

    function previewTimerCallback(){
        let now = new Date().getTime();
        if(now - updateTime < 0){
            //not ready to update yet
            setTimeout(previewTimerCallback, updateTime - now);
        } else {
            updateQuestionPreview();
        }
    }



    editor.addEventListener('input', (event) => {

        if(!previewTimer){
            previewTimer = setTimeout(previewTimerCallback, 1000);
        }
        //update the time on every keypress
        updateTime = new Date().getTime() + 1000;

    });

    document.getElementById('startPolling').addEventListener('click', (event) => {
        updateQuestionPreview(true);
    });

    updateQuestionPreview();
    tabs.select('qrCode');

}
