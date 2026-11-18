subroutine unique_values_positions_char(ivec,uniq,i1,i2)
! return in uniq(:) the unique character values in ivec
! and in i1(:) the first positions where they are found
character (len=*), intent(in)  :: ivec(:) ! (n)
character (len=*), intent(out), allocatable :: uniq(:)
integer, intent(out), allocatable  :: i1(:),i2(:)
integer :: i,ipos(size(ivec)),j,n,nuniq ! (n) positions of unique integers in ivec
n = size(ivec)
call unique_char(ivec,ipos,nuniq)
call set_alloc(ivec(ipos(:nuniq)),uniq)
call set_alloc(ipos(:nuniq),i1)
allocate (i2(nuniq))
i2 = n
do i=1,nuniq
   do j=i1(i)+1,n
      if (ivec(j) /= ivec(i1(i))) then
         i2(i) = j-1
         exit
      end if
   end do
end do
end subroutine unique_values_positions_char
!
