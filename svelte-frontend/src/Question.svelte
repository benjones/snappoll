<script lang="ts">

  let { question, answers} = $props()

</script>


<h3>{question}</h3>
<ul>
  {#each answers as answer}
    <li>{answer}</li>
  {/each}
  </ul>


<style>

 </style>
