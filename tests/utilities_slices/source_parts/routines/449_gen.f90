recursive subroutine gen(m,n_max,m_max,comb,comb_mat,zero_icomb)
! based on https://rosettacode.org/wiki/Combinations#Fortran
integer, intent(in)               :: m,n_max,m_max
integer, intent(in out)           :: comb(m_max)
integer, intent(in out)           :: comb_mat(:,:)
logical, intent(in)    , optional :: zero_icomb
integer                           :: n
integer, save                     :: icomb=0
logical                           :: call_gen
if (default(.false.,zero_icomb)) icomb = 0
if (m > m_max) then
   icomb = icomb + 1
   if (icomb <= size(comb_mat,1)) comb_mat(icomb,:) = comb
else
   do n = 1, n_max
      if (m == 1) then
         call_gen = .true.
      else if (n> comb(m - 1)) then
         call_gen = .true.
      else
         call_gen = .false.
      end if
      if (call_gen) then
         comb(m) = n
         call gen(m+1,n_max,m_max,comb,comb_mat)
      end if
   end do
end if
end subroutine gen
!
