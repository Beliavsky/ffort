program p
implicit none
integer::i,s
character(40)::line
character(2)::pool(3),words(3)
line='z a m'
read(line,*,iostat=s)pool
if(s/=0)error stop 1
words=[(max(pool(i),'b '),i=3,1,-1)]
print '(*(a))','[',words(1),'][',words(2),'][',words(3),']'
end program
