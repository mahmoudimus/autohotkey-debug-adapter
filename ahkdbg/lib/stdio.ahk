class StdIO
{
	__New()
	{
		; global hWait
		GENERIC_READ := 0x80000000  ; 以读取而不是写入的方式来打开文件.
		OPEN_EXISTING := 3  ; 此标志表示要打开的文件必须已经存在.
		FILE_SHARE_VALID_FLAGS := 0x00000007
		FILE_SHARE_READ := 0x1 ; 这个和下一个标志表示其他进程是否可以打开我们已经打开的文件.
		FILE_SHARE_WRITE := 0x2
		FILE_FLAG_OVERLAPPED := 0x40000000
		FILE_ATTRIBUTE_NORMAL := 0x00000080
		this.inStream := FileOpen("*", "r")
		; hStdin := DllCall("CreateFile","Str", "CONIN$","UInt", GENERIC_READ, "UInt", FILE_SHARE_VALID_FLAGS, "Ptr", 0, "UInt", OPEN_EXISTING
		; 		, "UInt", FILE_FLAG_OVERLAPPED, "Ptr", 0)
		; if (hStdin == -1)
		; 	Throw Exception("Open stdin fail", -1, DllCall("GetLastError", "Uint"))
		; pBindIoCallback := RegisterCallback(this.IoCompletionCallback)
		; if (!DllCall("BindIoCompletionCallback", "UInt", hFile, "UInt", pBindIoCallback, "UInt", 0))
		; 	Throw Exception("BindIoCompletionCallback fail", -1, DllCall("GetLastError", "Uint") " hFile: " hStdin)
		; this.outStream := FileOpen("*", "w", "utf-8")
	}

	ReadStdinAsync() {
		static read_handle := DllCall("GetStdHandle", "UInt", -10)
		static buffer_size := 4096
		static buffer := DllCall("GlobalAlloc", "UInt", 0x40, "UInt", buffer_size, "Ptr")
		static bytes_read := 0
	
		; Create the overlapped structure
		VarSetCapacity(overlapped, 20, 0)
		NumPut(0, overlapped, 0, "UInt")  ; Internal
		NumPut(0, overlapped, 4, "UInt")  ; Internal High
		NumPut(0, overlapped, 8, "UInt")  ; Offset
		NumPut(0, overlapped, 12, "UInt") ; Offset High
		NumPut(0, overlapped, 16, "UInt") ; hEvent
		rscb := RegisterCallback("ReadStdinCallback")

		; Check if there is any data available on stdin
		s := DllCall("ReadFileEx"
			, "Ptr", read_handle
			, "Ptr", buffer, "UInt", buffer_size
			, "Ptr", buffer
			, "Ptr", rscb, "UInt")
		if (!s) 
			throw Exception("ReadFileEx Not Succeed", -1)
		; Check if there was an error reading stdin
		if (ErrorLevel) {
			throw Exception("ReadFileEx Error: " ErrorLevel, -1)
		}
	}
	

	SetProcessor(callback) 
	{
		this.processer := callback
	}

	Process(s)
	{
		this.processer(s)
	}

	; IoCompletionCallback(dwErrorCode, dwNumberOfBytesTransfered, lpOverlapped)
	; {
	; 	ToolTip, % "ErrorCode: " ErrorCode " BytesTransfered: " dwNumberOfBytesTransfered
	; }

	Read(count := 0)
	{
		return this.inStream.Read()
		; FileRead, r, *
		; return r
	}

	ReadLine()
	{
		return this.inStream.ReadLine()
	}

	RawRead(Bytes)
	{
		buf := ""
		VarSetCapacity(buf, Bytes, 0)
		this.inStream.RawRead(buf, Bytes)
		str := StrGet(&buf, Bytes, "UTF-8")
		return str
	}

	Write(byref text)
	{
		; Some problem in call write method of outStream
		; Raw write to stdout by fileappend
		FileAppend %text%, *, UTF-8-RAW

		; outStream := FileOpen("*", "w `n", "utf-8")
		; VarSetCapacity(ps, StrLen(text)*3, 0)
		; Capacity := StrPut(text, &ps, "utf-8")
		; StrPut(text, &ps, Capacity, "utf-8")
		; outStream.RawWrite(&ps, Capacity-1)
		; outStream.Close()
		; outStream.Write(&ps)
		; this.outStream.Write(text)
		; this.inStream.Close()
		; outStream := FileOpen("*", "w", "utf-8")
		; outStream.Write(text)
		; outStream.Close()
		; this.inStream := FileOpen("*", "r")
	}

	__Delete()
	{
		global hWait
		this.inStream.Close()
		; this.outStream.Close()
		; if (hWait)
		; 	DllCall("UnregisterWaitEx", "Uint", hWait, "Uint", -1)
	}
}

ReadStdinCallback(dwErr, cbBytesRead, lpOverLap) 
{
	str := StrGet(lpOverLap, cbBytesRead, "UTF-8")
	MsgBox %str%
}

; OnStdin(lpParameter, TimerOrWaitFired) 
; {
; 	CallBackStd()
; }

; CallBackStd()
; {
; 	ToolTip, Console inputted!
; 	stdin := FileOpen("*", "r")
; 	text := stdin.Read()
; 	ToolTip, %text%
; }
