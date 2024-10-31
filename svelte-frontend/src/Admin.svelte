<script lang="ts">
  import svelteLogo from './assets/svelte.svg'
  import viteLogo from '/vite.svg'
  import Counter from './lib/Counter.svelte'

  function clickHandler(){
    console.log("clicked")
  }


  let selectedTab = $state('QRCode')

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
  {:else}
    <p>{selectedTab}</p>
  {/if}
  </div>


</main>

<style>
  #navbar {
    display: flex;
  }

  .navButton {
    padding:32px;
  }
</style>
