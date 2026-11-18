program p
implicit none
integer::stat
character(100)::text
character(10)::a,b
text="'a''b' " // achar(34) // 'c' // achar(34) // achar(34) // 'd' // achar(34)
read(text,*,iostat=stat)a,b
if(stat/=0.or.a/="a'b".or.b/='c"d')stop 1
print '(a)', "OK"
end program
