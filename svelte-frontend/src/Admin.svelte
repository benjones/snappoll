<script lang="ts">
  import QuestionEditor from './QuestionEditor.svelte'
  import PollResults from './PollResults.svelte'

  function clickHandler(){
    console.log("clicked")
  }


  async function startPolling(question){
    console.log(question);

    const response = await fetch("api/newQuestion", {
      method: 'POST',
      body: JSON.stringify(question),
      headers : {
        "Content-Type": "application/json"
      }
    })

    console.log("got response")
    console.log(response)

    if(response.ok){
      selectedTab = 'PollResults'
    }
  }

  let selectedTab = $state('QuestionEditor')



</script>

<main>

  <div id="navbar">
    <a href="#/" class="navButton" onclick={()=>{selectedTab = 'QRCode'}} >QR Code</a>
    <a href="#/" class="navButton" onclick={()=>{selectedTab = 'QuestionEditor'}} >Question Editor</a>
    <a href="#/" class="navButton" onclick={()=>{selectedTab = 'PollResults'}} >Poll Results</a>
    </div>


  <div id="mainContent">
  {#if selectedTab == 'QRCode'}
    <img src="qrCode" alt="QR Code for polling.  Todo, put the actual URL in the alt text somehow" />
  {:else if selectedTab =='QuestionEditor'}
    <QuestionEditor startPollingCallback={startPolling} />
  {:else}
    <PollResults />
  {/if}
  </div>


</main>

<style>

  main {
    display: flex;
    flex-direction: column;
    align-items: center;
  }

  #navbar {
    display: flex;
    flex:0;
  }

  #mainContent {
    width: auto;
  }

  .navButton {
    padding:32px;
  }
</style>
