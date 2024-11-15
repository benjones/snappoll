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


</script>

<main>
  <Question {...currentQuestion} />
</main>

<style>
</style>
