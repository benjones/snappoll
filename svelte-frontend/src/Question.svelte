<script lang="ts">

  let { question, answers, onComplete} = $props()

  function handler(index){
    return async function (event){
      console.log(index);
      console.log(event);

      const response = await fetch('api/vote', {
        method: 'POST',
        body: JSON.stringify({'option': index}),
        headers : {
          "Content-Type": "application/json"
        }
      })
      console.log("got response")
      console.log(response)

      if(response.ok){
        if(onComplete){
          onComplete()
        }
      }
    }
  }

</script>


<div>
<h3>{question}</h3>
  {#each answers as answer, i}
    <button onclick={handler(i)}>{answer}</button>
  {/each}
</div>

<style>
  div {
    max-width: 800px;
    margin: auto; /*center horizontally*/
  }

  button {
    width: 80%;
    padding: 16px;
    margin: 8px;
  }
 </style>
