program demo
implicit none
character(3) :: words(2,2,2)
integer :: answers(2,2,2),i,j,k
words='abc'
words(2,1,2)='cab'
answers=scan(words,'a')
where(verify(words(:,:,2),'ab')>0)
 answers(:,:,2)=answers(:,:,2)+10
elsewhere
 answers(:,:,2)=0
end where
print *,answers(:,:,1),answers(:,:,2)
end program
