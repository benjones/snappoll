<script lang="ts">
  import QuestionEditor from './QuestionEditor.svelte'

  function clickHandler(){
    console.log("clicked")
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
    <QuestionEditor />
  {:else}
    <p>{selectedTab}</p>
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
