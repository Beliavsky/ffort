program demo
implicit none
character(3)::words(1,2,2)
logical::back(1,2,2)
integer::answer(1,2,2)
words='aba'
back=.true.
call search(words,answer)
print *,answer
call search(words,answer,back)
print *,answer
contains
subroutine search(words,answer,back)
character(*),intent(in)::words(:,:,:)
integer,intent(out)::answer(:,:,:)
logical,optional,intent(in)::back(:,:,:)
answer=scan(words,'a',back)
end subroutine
end program
