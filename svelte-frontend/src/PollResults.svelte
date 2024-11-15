<script lang="ts">

  let question = { "question": "This is the question",
                   "answers" : ["one", "two", "three"]}

  let votes  = [5, 8, 4]
  let maxVotes = $derived( Math.max(1, ...votes))

  $effect(()=>{

    const evtSource = new EventSource("/eventStream");
    evtSource.onmessage = (event) => {
      console.log(event.data)
    }
    evtSource.onerror = (err) => {
      console.log("evt source error: ")
      console.log(err)
    }
    console.log("SSE setup")
    return () => {evtSource.close() }
  })

</script>

<div id="container">
  {#each question['answers'] as answer, i}
    <div class="row">
      <div class="bar" style="width: {100*votes[i]/maxVotes}%"></div>
      <div class="answerContent">
        <p>{answer}</p>
        <p>{votes[i]}</p>
      </div>
    </div>

  {/each}

</div>

<style>

  #container {
    max-width:1000px;
    min-width:400px;
  }

  .row {
    position: relative;
    width: 95%;
    margin: 8px;
  }

  .bar {
    position: absolute;
    top: 0;
    left: 0;
    height: 100%;
    background-color: #032970;
    z-index: -1;

  }
  .answerContent {
    display: flex;
    justify-content: space-between;
    padding: 16px;

  }

</style>
