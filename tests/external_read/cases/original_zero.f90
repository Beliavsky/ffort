module utility_slice
implicit none
contains
subroutine read_words_line(iu,words,nread,echo,label)
! read words from line, where the line has the # of words followed by the words
! n word_1 word_2 ... word_n
integer          , intent(in)               :: iu
character (len=*), intent(out), allocatable :: words(:)
integer          , intent(out), optional    :: nread
character (len=*), intent(in) , optional    :: label
logical          , intent(in) , optional    :: echo
character (len=10000)                       :: text
integer                                     :: i,ierr,nread_,nw
read (iu,"(a)") text
read (text,*,iostat=ierr) nw
if (ierr /= 0) then
   write (*,*) "in read_words_line, could not read integer from '" // trim(text) // "', STOPPING"
   stop
end if
if (nw > 0) then
   allocate (words(nw))
   read (text,*,iostat=ierr) nw,words
   if (ierr /= 0) then
      write (*,*) "in read_words_line, could not read",nw," words from '" // trim(text) // "', STOPPING"
      stop
   end if
else
   allocate (words(0))
end if
nread_ = size(words)
if (present(nread)) nread = nread_
if (default(.false.,echo)) then
   if (present(label)) write (*,*) trim(label) // ":"
   write (*,*) (trim(words(i)) // " ",i=1,nread_)
   write (*,*)
end if
end subroutine read_words_line
logical function default(value,option) result(answer)
logical,intent(in)::value
logical,intent(in),optional::option
answer=value
if(present(option)) answer=option
end function
end module
program p
use utility_slice
implicit none
integer::u,n
character(4),allocatable::words(:)
u=27
call read_words_line(u,words,n)
if(n/=0.or.size(words)/=0)stop 1
print '(a)', 'OK'
end program
