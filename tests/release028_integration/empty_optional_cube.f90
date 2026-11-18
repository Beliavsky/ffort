program demo
implicit none
character(0)::words(0,2,2)
integer::answer(0,2,2)
call search(words,answer)
print *,size(answer),size(answer,2),size(answer,3)
contains
subroutine search(words,answer,back)
character(*),intent(in)::words(:,:,:)
integer,intent(out)::answer(:,:,:)
logical,optional,intent(in)::back(:,:,:)
answer=verify(words,'a',back)
end subroutine
end program
