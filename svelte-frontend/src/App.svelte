<script lang="ts">

  import Question from './Question.svelte'

  let currentQuestion = $state({ "question" : "How do you do fellow teens?",
                                 "answers" : ["OK", "Fine", "Meh"]
                               })


</script>

<main>
  <Question {...currentQuestion} />
</main>

<style>
</style>
