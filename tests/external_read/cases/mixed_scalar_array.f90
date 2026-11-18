program p
implicit none
integer::n,stat
character(50)::text
character(4)::words(3)
text='3 red blue tan'
read(text,*,iostat=stat)n,words
if(stat/=0.or.n/=3.or.any(words/=['red ','blue','tan ']))stop 1
print '(a)', "OK"
end program
