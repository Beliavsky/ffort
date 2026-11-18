subroutine row_count_changes(tf_mat,irows,ntrue)
logical, intent(in)               :: tf_mat(:,:)
integer, intent(out), allocatable :: irows(:),ntrue(:)
call changes_positions(count_rows(tf_mat),irows,ntrue)
end subroutine row_count_changes
!
