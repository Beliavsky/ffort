program p
implicit none
integer::stat
character(30)::text
character(2)::a
character(5)::b(2)
text="3*'abcd'"
read(text,*,iostat=stat)a,b
if(stat/=0.or.a/='ab'.or.any(b/='abcd '))stop 1
print '(a)', "OK"
end program
