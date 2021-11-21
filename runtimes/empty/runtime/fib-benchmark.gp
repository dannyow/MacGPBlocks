// to print args... {
//   result = (list)
//   for i (argCount) {
//     add result (toString (arg i))
//     if (i != (argCount)) {add result ' '}
//   }
//   log (joinStringArray (toArray result))
// }


// to benchFib2 n {
//   if (n < 2) { return 1 }
//   return (+ (benchFib (n - 1)) (benchFib (n - 2)) 1)
// }
// let fibonacci = func(x) {
// 	if (x == 0) {
// 		0
// 	} else {
// 		if (x == 1) {
// 			return 1;
// 		} else {
// 			fibonacci(x - 1) + fibonacci(x - 2);
// 		}
// 	}
// };
to fib1 n {
  if (n < 2) { return n }
  return (+ (fib1 (n - 1)) (fib1 (n - 2)) )
}

// def fib(n: Int): Int = {
//         def fib(n: Int, p :Int, c: Int): Int ={
//           if (n == 0) return -1; // undefined
//           if (n == 1) return p;
//           fib(n-1, c, p + c)
//         }
//         fib(n, 0, 1);
//       }

// https://dotink.co/docs/overview/#:~:text=Ink%20functions%20support%20proper%20tail%20recursion%2C%20and%20tail%20recursion%20is%20the%20conventional%20and%20idiomatically%20way%20to%20create%20loops%20in%20Ink%20programs.%20For%20example%2C%20a%20naive%20fibonacci%20function%20looks%20simple.
to fib2Priv n p c {
  // log 'n' n p c 
  if (n == 0) { return -1} //undefined
  if (n == 1) {return p}
  return (fib2Priv (n - 1) c (p + c) )
}

to fib2 n {
  return (fib2Priv n 0 1)

}


to bench {

  max = 35
  start = (msecsSinceStart)
  v = (fib2 max)
  msecs = ((msecsSinceStart) - start)
  log 'fib1:' max (msecs / 1000) 'v=' v


}


bench