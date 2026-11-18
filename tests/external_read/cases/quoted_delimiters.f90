program p
implicit none
integer::n,stat
character(100)::text
character(12)::words(4)
text="4 'a b' 'c,d' 'e/f' '2*x'"
read(text,*,iostat=stat)n,words
if(stat/=0.or.n/=4)stop 1
if(words(1)/='a b'.or.words(2)/='c,d'.or.words(3)/='e/f'.or.words(4)/='2*x')stop 2
print '(a)', "OK"
end program
