
<script lang="ts">

  import Question from './Question.svelte'

  let userText = `Edit your question on the left.  The first line is the question?
And each line is
One
Possible
Answer`

  function parseQuestion(text){
    const lines = text.split('\n');
    return { question: lines[0],
             answers: lines.slice(1)
           }
  }

</script>

<div id="container">

  <textarea bind:value={userText}>asdf</textarea>

  <div id="previewPane">
    <Question {...parseQuestion(userText)} />
  </div>

</div>



<style>
  #container {
    display: grid;
    grid-template-columns: 1fr 1fr;
    max-width:1000px;
  }

  textarea {

  }

  #previewPane {

  }

</style>
