<script lang="ts">

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

<div>
  <p> poll results component</p>
</div>

<style>

</style>
