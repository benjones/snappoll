<script lang="ts">

  import Question from './Question.svelte'

  //this is the student page

  let currentQuestion = $state({ "question" : "How do you do fellow teens?",
                                 "answers" : ["OK", "Fine", "Meh"]
                               })
  //load the first question asynchronously
  $effect(async ()=>{
    let response = await fetch("api/currentQuestion")
    currentQuestion = await response.json()
  })

  let voted = $state(false)

</script>

<main>
  {#if voted}
  <p>Vote recorded</p>
  {:else}
  <Question question={currentQuestion.question} answers={currentQuestion.answers} onComplete={()=>{
    voted = true
    }} />
  {/if}
</main>

<style>
</style>
