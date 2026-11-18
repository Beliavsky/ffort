module combined_numeric_character
contains
subroutine transform(words,mask,codes,label)
character(*),intent(inout)::words(:)
logical,optional,intent(in)::mask(:)
integer,optional,intent(out)::codes(:)
character(*),optional,intent(inout)::label
integer::i
if(present(mask)) then
 do i=1,size(words)
  if(mask(i)) words(i)=adjustl(words(i))
 end do
end if
if(present(codes)) codes=index(words,'a')+len_trim(words)
if(present(label)) label(2:len(label))=adjustl(label(2:))
end subroutine
end module
program p
use combined_numeric_character
implicit none
character(6)::words(3),label='[ hi  '
integer::codes(3)
words=[character(6)::' a*',' bb','c']
call transform(words)
call transform(words,[.true.,.false.,.true.],codes,label)
print *,codes
print '(3a)',words
print '(a)',label
end program
