while true:
  block :stateLoop:
    try:
      var
        :tmpD
        :tmpD_1
        :tmpD_2
        :tmpD_3
      closureIterSetupExc(:envP.`:curExc1`)
      goto :envP.`:state`6
      state 0:
      template result(): auto {.used.} =
        {.fatal: "You should not reference the `result` variable inside" &
            " a void async proc".}

      var :envP.closureSucceeded25 = true
      :envP.`:state` = 1
      break :stateLoop
      state 1:
      var :envP.obj117 =
        type
          OutType`gensym13 = typeof(items("hello world! " & $i))
        block :tmp:
          :tmpD =
            let :envP.`:tmp5` = `&`("hello world! ", $:envP.`:up`.i1)
            template s2_838861096(): untyped =
              :tmp_1
            
            var :envP.i`gensym1310 = 0
            var :envP.result`gensym139 = newSeq(
                chckRange(len(:envP.`:tmp5`), 0, 9223372036854775807))
            block :tmp_2:
              var :envP.it`gensym138
              var :envP.i6 = 0
              let :envP.L7 = len(:envP.`:tmp5`)
              block :tmp_3:
                while :envP.i6 < :envP.L7:
                  :envP.it`gensym138 = :envP.`:tmp5`[:envP.i6]
                  :envP.result`gensym139[:envP.i`gensym1310] = :envP.it`gensym138
                  :envP.i`gensym1310 += 1
                  inc(:envP.i6, 1)
                  const
                    loc`gensym22 = (filename: "/Users/elcritch/.asdf/installs/nim/1.6.18/lib/system/iterators.nim",
                      line: 258, column: 10)
                    ploc`gensym22 = "/Users/elcritch/.asdf/installs/nim/1.6.18/lib/system/iterators.nim(258, 11)"
                  bind instantiationInfo
                  mixin failedAssertImpl
                  {.line: (filename: "/Users/elcritch/.asdf/installs/nim/1.6.18/lib/system/iterators.nim",
                           line: 258, column: 10).}:
                    if not (len(:envP.`:tmp5`) == :envP.L7):
                      failedAssertImpl("/Users/elcritch/.asdf/installs/nim/1.6.18/lib/system/iterators.nim(258, 11) `len(a) == L` the length of the string changed while iterating over it")
            :envP.result`gensym139
          :tmpD
      var :envP.obj218 =
        type
          OutType`gensym20 = typeof(items("goodbye denver!"))
        block :tmp_4:
          :tmpD_1 =
            let :envP.`:tmp11` = "goodbye denver!"
            template s2_838861153(): untyped =
              :tmp_5
            
            var :envP.i`gensym2016 = 0
            var :envP.result`gensym2015 = newSeq(
                chckRange(len(:envP.`:tmp11`), 0, 9223372036854775807))
            block :tmp_6:
              var :envP.it`gensym2014
              var :envP.i12 = 0
              let :envP.L13 = len(:envP.`:tmp11`)
              block :tmp_7:
                while :envP.i12 < :envP.L13:
                  :envP.it`gensym2014 = :envP.`:tmp11`[:envP.i12]
                  :envP.result`gensym2015[:envP.i`gensym2016] = :envP.it`gensym2014
                  :envP.i`gensym2016 += 1
                  inc(:envP.i12, 1)
                  const
                    loc`gensym22 = (filename: "/Users/elcritch/.asdf/installs/nim/1.6.18/lib/system/iterators.nim",
                      line: 258, column: 10)
                    ploc`gensym22 = "/Users/elcritch/.asdf/installs/nim/1.6.18/lib/system/iterators.nim(258, 11)"
                  bind instantiationInfo
                  mixin failedAssertImpl
                  {.line: (filename: "/Users/elcritch/.asdf/installs/nim/1.6.18/lib/system/iterators.nim",
                           line: 258, column: 10).}:
                    if not (len(:envP.`:tmp11`) == :envP.L13):
                      failedAssertImpl("/Users/elcritch/.asdf/installs/nim/1.6.18/lib/system/iterators.nim(258, 11) `len(a) == L` the length of the string changed while iterating over it")
            :envP.result`gensym2015
          :tmpD_1
      var :envP.data20 = @[
        :tmpD_2 = :envP.obj117
        :tmpD_2,
        :tmpD_3 = :envP.obj218
        :tmpD_3]
      block :tmp_8:
        var
          :tmpD_4
          :tmpD_5
          :tmpD_6
          :tmpD_7
        let :envP.taskNode23 = new(TaskNode, workerContext.currentTask) do:
          type
            ScratchObj = object
              data: seq[seq[char]]
              sig: ThreadSignalPtr

          let :envP.scratch19 = cast[ptr ScratchObj](c_calloc(1'u, 16'u))
          if isNil(:envP.scratch19):
            raise
              (ref OutOfMemDefect)(msg: "Could not allocate memory", parent: nil)
          block :tmp_9:
            var
              :tmpD_8
              :tmpD_9
            `=sink`(:envP.isoTemp21, isolate do:
              :tmpD_8 = :envP.data20
              :tmpD_8)
            :envP.scratch19.data = extract(:envP.isoTemp21)
            `=sink_1`(:envP.isoTemp22, isolate do:
              :tmpD_9 = :envP.`:up`.sig2
              :tmpD_9)
            :envP.scratch19.sig = extract_1(:envP.isoTemp22)
          proc worker_838861197(args`gensym27: pointer) {.gcsafe, nimcall,
              raises: [].} =
            let objTemp = cast[ptr ScratchObj](args`gensym27)
            let data_1 = objTemp.data
            let sig_1 = objTemp.sig
            worker(data_1, sig_1)

          proc destroyScratch_838861198(args`gensym27_1: pointer) {.gcsafe,
              nimcall, raises: [].} =
            let obj = cast[ptr ScratchObj](args`gensym27_1)
            `=destroy`(obj[])

          Task(callback:
            :tmpD_4 = worker_1
            :tmpD_4, args:
            :tmpD_5 = :envP.scratch19
            :tmpD_5, destroy:
            :tmpD_6 = destroyScratch
            :tmpD_6)
        schedule(workerContext):
          :tmpD_7 = :envP.taskNode23
          :tmpD_7
      chronosInternalRetFuture.internalChild = FutureBase(wait(:envP.`:up`.sig2))
      :envP.`:state` = 4
      return chronosInternalRetFuture.internalChild
      state 2:
      :envP.`:curExc1` = nil
      if of(getCurrentException(), CancelledError):
        :envP.closureSucceeded25 = false
        cancelAndSchedule(FutureBase(cast[Future[void]](chronosInternalRetFuture)),
                          srcLocImpl("", "exNoFailureSeqSeq.nim", 43))
      elif of(getCurrentException(), CatchableError):
        let :envP.exc26 = getCurrentException()
        :envP.closureSucceeded25 = false
        failImpl(FutureBase(cast[Future[void]](chronosInternalRetFuture)),
                 :envP.exc26, srcLocImpl("", "exNoFailureSeqSeq.nim", 43))
      elif of(getCurrentException(), Defect):
        var :tmpD_10
        let :envP.exc27 = getCurrentException()
        :envP.closureSucceeded25 = false
        raise
          :tmpD_10 = :envP.exc27
          :tmpD_10
      else:
        :envP.`:unrollFinally3` = true
        :envP.`:curExc1` = getCurrentException()
        :envP.`:state` = 3
        break :stateLoop
      :envP.`:state` = 3
      break :stateLoop
      state 3:
      if :envP.closureSucceeded25:
        complete(cast[Future[void]](chronosInternalRetFuture),
                 srcLocImpl("", "exNoFailureSeqSeq.nim", 43))
      if :envP.`:unrollFinally3`:
        if `==`(:envP.`:curExc1`, nil):
          :envP.`:state` = -1
          return result = :envP.`:tmpResult2`
        else:
          var :tmpD_11
          closureIterSetupExc(nil)
          raise
            :tmpD_11 = :envP.`:curExc1`
            :tmpD_11
      :envP.`:state` = 6
      break :stateLoop
      state 4:
      {.cast(raises: [AsyncError, CancelledError]).}:
        if isNil(cast[type(wait(sig_2))](chronosInternalRetFuture.internalChild).internalError):
          discard
         else:
          var :tmpD_12
          raise
            :tmpD_12 = cast[type(wait(sig_2))](chronosInternalRetFuture.internalChild).internalError
            :tmpD_12
      :envP.`:state` = 5
      break :stateLoop
      state 5:
      echo ["data: ", repr(pointer(addr(:envP.data20)))]
      echo ["data: ", `$_1`(:envP.data20)]
      echo [""]
      :envP.`:state` = 3
      break :stateLoop
      state 6:
      :envP.`:state` = -1
      break :stateLoop
    except:
      :envP.`:state` = [0, -2, 3, 0, -2, -2, 0][:envP.`:state`]
      if `==`(:envP.`:state`, 0):
        raise
      :envP.`:unrollFinally3` = `<`(0, :envP.`:state`)
      if `<`(:envP.`:state`, 0):
        :envP.`:state` = `-`(:envP.`:state`)
      :envP.`:curExc1` = getCurrentException()