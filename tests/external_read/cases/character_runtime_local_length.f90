module m
contains
subroutine read_words(n)
integer,intent(in)::n
character(n)::words(2)
character(20)::text
integer::stat
text='apple b'
read(text,*,iostat=stat)words
if(stat/=0.or.len(words)/=n.or.words(1)/='app'.or.words(2)/='b')stop 1
end subroutine
end module
program p
use m
implicit none
call read_words(3)
print '(a)','OK'
end program
