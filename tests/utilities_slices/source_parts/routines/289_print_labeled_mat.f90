subroutine print_labeled_mat(sym,xx,sym_label,xlabel,outu,fmt_header,fmt_trailer,abs_min,print_num_printed, &
                             order,fmt_labels,fmt_sym_xx)
! print vector xx(:) with labels sym(:) and column names sym_label and xlabel
character (len=*), intent(in)           :: sym(:)    ! (n)
real(kind=dp)    , intent(in)           :: xx(:,:)   ! (n,ncol)
character (len=*), intent(in)           :: sym_label ! labels for character and real data
character (len=*), intent(in)           :: xlabel(:) ! (ncol)
integer          , intent(in), optional :: outu
character (len=*), intent(in), optional :: fmt_header,fmt_trailer
real(kind=dp)    , intent(in), optional :: abs_min
logical          , intent(in), optional :: print_num_printed ! print the # of elements that will printed and the size of xx(:)
character (len=*), intent(in), optional :: order
character (len=*), intent(in), optional :: fmt_sym_xx,fmt_labels
integer                                 :: i,j,n,outu_,indx(size(xx,1))
real(kind=dp)                           :: abs_min_
character (len=100)                     :: fmt_labels_,fmt_sym_xx_
call set_optional(fmt_labels_,"(1000a15)",fmt_labels)
call set_optional(fmt_sym_xx_,"(a15,1000f15.4)",fmt_sym_xx)
n = size(sym)
outu_ = default(istdout,outu)
call assert_equal("in print_labeled_mat, size(sym), size(xx) =",n,size(xx,1))
if (n < 1) return
abs_min_ = default(-1.0_dp,abs_min)
call write_format(fmt_header,outu_)
if (default(.false.,print_num_printed)) &
   write (outu_,"('#>=thresh, total, thresh, abs_min_ =',2(1x,i0),g12.6)") count(xx(:,1) > abs_min_),n,abs_min_
indx = indexx_order(xx(:,1),order)
write (outu_,fmt_labels_) trim(sym_label),(trim(xlabel(i)),i=1,size(xlabel))
do j=1,n
   i = indx(j)
   if (abs(xx(i,1)) >= abs_min_) write (outu_,fmt_sym_xx_) trim(sym(i)),xx(i,:)
end do
call write_format(fmt_trailer,outu_)
end subroutine print_labeled_mat
!
