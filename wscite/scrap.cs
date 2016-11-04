		public Func<object, string, bool> BeginConnection;
		public Action<object> EndConnection;
		public Action<object,string> ConnectionData;

		public void ReplyToMaster( string text )
		{
			if( TraceCommands )
				Debug.WriteLine( "Remote." + Port + ": SendPort: " + text );
			SerialPort.WriteLine( text );
		}

		public string ReadLineFromMaster()
		{
			//SerialPort.DiscardInBuffer();
			for( ; ; )
			{
				try
				{
					return SerialPort.ReadLine();
				}
				catch( Exception e )
				{
					if( TraceErrors )
						Debug.WriteLine( "Remote.ReadLine." + Port + ": Exception: " + e.Message );
					continue;
				}
			}
		}

		public bool Invoke_USB_ConnectionBegin( object sender, string hostname )
		{
			Debug.WriteLine( "USB_ConnectionBegin.Begin: " + hostname );

			IAsyncResult aResult
				= BeginInvoke(
					new Func<string,bool>( USB_ConnectionBegin ),
					new object[] { hostname } );

			bool result = (bool)EndInvoke( aResult );

			Debug.WriteLine( "USB_ConnectionBegin.End: " + result.ToString() );

			return result;
		}
